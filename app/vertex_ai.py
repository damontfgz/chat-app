from chromadb import Settings
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from google import genai
from google.genai.types import HttpOptions

from langchain import PromptTemplate
# from langchain import HuggingFacePipeline
from langchain_google_vertexai import VertexAI

from langchain.vectorstores import Chroma
# from langchain.schema import AIMessage, HumanMessage
from langchain.memory import ConversationBufferMemory
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import UnstructuredMarkdownLoader, UnstructuredURLLoader
from langchain.chains import LLMChain, SimpleSequentialChain, RetrievalQA, ConversationalRetrievalChain

# from transformers import BitsAndBytesConfig, AutoModelForCausalLM, AutoTokenizer, GenerationConfig, pipeline

import warnings

warnings.filterwarnings('ignore')



app = FastAPI()

client = genai.Client(http_options=HttpOptions(api_version="v1"))


async def generate_stream_content(prompt: str):
    for chunk in client.models.generate_content_stream(
            model="gemini-2.0-flash-001",
            contents=prompt
    ):
        yield chunk.text


@app.post("/chat/vertex")
async def chat_vertex(request: Request):
    try:
        payload = await request.json()
        prompt = payload.get("prompt", "")

        return StreamingResponse(generate_stream_content(prompt), media_type="text/plain")

    except Exception as e:
        print(f"error: {e}")
        return {"error": str(e)}



embeddings = HuggingFaceEmbeddings(
    model_name="thenlper/gte-large",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"normalize_embeddings": True},
)

template = """
[INST] <>
Act as an Hiberus marketing manager expert. Use the following information to answer the question at the end.
<>

{context}

{question} [/INST]
"""

prompt = PromptTemplate(template=template, input_variables=["context", "question"])

urls = [
    "https://www.hiberus.com/expertos-ia-generativa-ld",
    "https://www.hiberus.com/en/experts-generative-ai-ld"
]

loader = UnstructuredURLLoader(urls=urls)
documents = loader.load()

text_splitter = RecursiveCharacterTextSplitter(chunk_size=1024, chunk_overlap=64)
texts_chunks = text_splitter.split_documents(documents)

db = Chroma.from_documents(
    texts_chunks,
    embeddings,
    persist_directory="db",
    client_settings=Settings(anonymized_telemetry=False)
)
llm = VertexAI(model_name="gemini-2.0-flash-001")

qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=db.as_retriever(search_kwargs={"k": 2}),
    return_source_documents=True,
    chain_type_kwargs={"prompt": prompt},
)


@app.post("/chat/rag")
async def chat_rag(request: Request):
    try:
        payload = await request.json()
        query = payload.get("prompt", "")
        response = qa_chain({"query": query})
        return {"response": response["result"], }

    except Exception as e:
        print(f"error: {e}")
        return {"error": str(e)}


custom_template = """
You are an Hiberus Marketing Manager AI Assistant. Given the
following conversation and a follow up question, rephrase the follow up question
to be a standalone question. At the end of standalone question add this
'Answer the question in English language.' If you do not know the answer reply with 'I am sorry, I dont have enough information'.
Chat History:
{chat_history}
Follow Up Input: {question}
Standalone question:
"""

CUSTOM_QUESTION_PROMPT = PromptTemplate.from_template(custom_template)

memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)
conversation_chain = ConversationalRetrievalChain.from_llm(
    llm=llm,
    retriever=db.as_retriever(search_kwargs={"k": 2}),
    memory=memory,
    condense_question_prompt=CUSTOM_QUESTION_PROMPT,
)


@app.post("/chat/conversation_rag")
async def chat_conversation_rag(request: Request):
    try:
        payload = await request.json()
        query = payload.get("prompt", "")

        response = conversation_chain({"question": query})
        return {"response": response["answer"], }

    except Exception as e:
        print(f"error: {e}")
        return {"error": str(e)}