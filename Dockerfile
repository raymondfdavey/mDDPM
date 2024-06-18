FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Install git
RUN apt-get update && apt-get install -y git

# Clone the HD-BET repository
RUN git clone https://github.com/MIC-DKFZ/HD-BET.git /app/HD-BET

# Change to the HD-BET directory and install it
WORKDIR /app/HD-BET
RUN pip install -e .

# Change back to the main working directory
WORKDIR /app

# Copy the requirements file to the working directory
COPY requirements.txt .

# Install the required packages
RUN pip install -r requirements.txt

# Copy the main repository to the working directory
COPY . .

# Change to the preprocessing directory
WORKDIR /app/preprocessing

# Set the entry point to run your bash script with the INPUT_PATH and OUTPUT_PATH arguments
ENTRYPOINT ["bash", "prepare_IXI.sh", "$INPUT_PATH", "$OUTPUT_PATH"]