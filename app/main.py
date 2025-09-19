import random

from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import redis
from langchain_google_memorystore_redis import MemorystoreChatMessageHistory
from langchain_google_memorystore_redis import (
    DistanceStrategy,
    HNSWConfig,
    RedisVectorStore,
)
from langchain_openai import ChatOpenAI


from langchain import PromptTemplate
from langchain.chains import ConversationalRetrievalChain, LLMChain
from langchain.memory import ConversationBufferMemory
from langchain.embeddings import HuggingFaceEmbeddings

import gradio as gr
from gradio.routes import mount_gradio_app
import json
import httpx
import os
import re

cname = os.getenv("VLLM_CNAME", default="localhost")
port = os.getenv("VLLM_PORT", default="8080")
VLLM_URL = f"http://{cname}:{port}/v1/chat/completions"

MEMORYSTORE_URL = os.getenv("MEMORYSTORE_URL", default="redis://localhost:6379")

CSS = """
.small-font * {
    font-size: 12px !important;
}
"""

app = FastAPI()

embeddings = HuggingFaceEmbeddings(
    model_name="thenlper/gte-large",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"normalize_embeddings": True},
)

redis_client = redis.cluster.RedisCluster.from_url(MEMORYSTORE_URL)
index_config = HNSWConfig(
    name="chat_vs:", distance_strategy=DistanceStrategy.COSINE, vector_size=768
)

try:
    RedisVectorStore.init_index(client=redis_client, index_config=index_config)
except redis.exceptions.ResponseError as e:
    if re.match(r".*already exists", str(e)):
        print("Index already exists, skipping creation.")
    else:
        raise

vector_store = RedisVectorStore(
    client=redis_client, index_name="chat_vs:", embeddings=embeddings
)

chat_history = MemorystoreChatMessageHistory(
    client=redis_client,
    session_id="id" + str(random.randint(0, 10))
)

prompt = PromptTemplate(
    template="""Use all the information from the context and the conversation history to continue conversation. \
If you see the answer in previous conversation history or the context. Try to satisfy the user if possible

Previous conversation history from the user. "Human" was the user who's asking the new question. "Assistant" was you as the assistant:
```{chat_history}
```

Vector search result of the new question:
```{context}
```

New Input:
```{question}```

Answer:""",
    input_variables=["context", "question", "chat_history"],
)
condense_question_prompt_passthrough = PromptTemplate(
    template="""Repeat the following question:
{question}
""",
    input_variables=["question"],
)

memory = ConversationBufferMemory(
    memory_key="chat_history",
    chat_memory=chat_history,
    output_key="answer",
    return_messages=True)

custom_llm = ChatOpenAI(
    openai_api_base=f"http://{cname}:{port}/v1",
    openai_api_key="EMPTY",
    model_name="google/gemma-3-1b-it",
    streaming=True,
    temperature=0.0,
)

# template = (
#     "Combine the chat history and follow up question into "
#     "a standalone question. Chat History: {chat_history}"
#     "Follow up question: {question}"
# )
# prompt = PromptTemplate.from_template(template)

conversation_chain = ConversationalRetrievalChain.from_llm(
    llm=custom_llm,
    retriever=vector_store.as_retriever(search_type="mmr", search_kwargs={"k": 5, "lambda_mult": 0.8}),
    memory=memory,
    condense_question_prompt=condense_question_prompt_passthrough,
    combine_docs_chain_kwargs={"prompt": prompt},
)


# question_generator_chain = LLMChain(llm=custom_llm, prompt=prompt)
# chain = ConversationalRetrievalChain(
#     retriever=vector_store.as_retriever(search_type="mmr", search_kwargs={"k": 5, "lambda_mult": 0.8}),
#     question_generator=question_generator_chain,
# )
#
# async def stream_rag_chain_response_v2(prompt):
#     try:
#         response = await chain.arun({"question": prompt, "chat_history": chat_history})
#         yield response
#     except Exception as e:
#         yield f"Error: {str(e)}"

async def stream_rag_chain_response(prompt):
    try:
        response = await conversation_chain.arun({"question": prompt, "chat_history": chat_history})
        yield response
    except Exception as e:
        yield f"Error: {str(e)}"


async def stream_response(prompt):
    async with httpx.AsyncClient(timeout=None) as client:
        async with client.stream(
                "POST",
                VLLM_URL,
                json={
                    "model": "google/gemma-3-1b-it",
                    "messages": [{"role": "user", "content": prompt}],
                    "stream": True
                },
        ) as response:
            async for line in response.aiter_lines():
                if not line.strip().startswith("data:"):
                    continue
                try:
                    payload = json.loads(line.removeprefix("data: ").strip())
                    chunk = payload.get("choices", [{}])[0].get("delta", {}).get("content")
                    yield chunk
                except json.JSONDecodeError:
                    continue

with gr.Blocks(theme="soft", css=CSS) as demo:

    chatbot = gr.Chatbot(type="messages", elem_classes=["small-font"])
    msg = gr.Textbox(elem_classes=["small-font"])
    clear = gr.ClearButton([msg, chatbot])

    async def user(user_message, history: list):
        return "", history + [{"role": "user", "content": user_message}]

    async def bot(history: list):
        user_input = history[-1]["content"]
        history.append({"role": "assistant", "content": ""})
        async for chunk in stream_rag_chain_response(user_input):
            history[-1]["content"] += chunk
            yield history

    msg.submit(user, [msg, chatbot], [msg, chatbot], queue=False).then(
        bot, chatbot, chatbot
    )
    clear.click(lambda: None, None, chatbot, queue=False)

# demo.launch()





@app.post("/chat/vllm")
async def generate(request: Request):
    body = await request.json()
    prompt = body.get("prompt", "")
    return StreamingResponse(stream_rag_chain_response(prompt), media_type="text/plain")

app = mount_gradio_app(app, demo, path="/gradio")

