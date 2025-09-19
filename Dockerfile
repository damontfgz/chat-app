# ---- Builder Stage ----
# Use a full Python image to build our dependencies
FROM python:3.10 as builder

# Set the working directory
WORKDIR /install

# Install sentence-transformers with a CPU-only version of PyTorch
# This is the key step to reduce the size. We specify the PyTorch version and that we don't need CUDA.
RUN pip install --no-cache-dir \
    torch==2.3.1 --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir sentence-transformers


# Use a slim base image with Python
FROM python:3.10-slim

# Install system packages
RUN apt-get update && apt-get install -y \
    git build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Install Python packages
COPY app/. .
RUN pip install --no-cache-dir -r requirements.txt

# EXPOSE 7860
# ENV GRADIO_SERVER_NAME="0.0.0.0"
#
# # Expose port and run FastAPI server
# CMD ["fastapi", "run", "main.py"]
EXPOSE 8000
ENV GRADIO_SERVER_NAME="0.0.0.0"

# Start FastAPI app using uvicorn (Gradio is mounted inside)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]