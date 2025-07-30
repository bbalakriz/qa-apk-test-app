# QA APK Test Automation - Container Image
# This container includes everything except the Android emulator  
# Works with both Podman and Docker
# EXACT VERSIONS ALIGNED: Node 18.20.8, OpenJDK 17.0.16, ADB 1.0.41

FROM node:18.20.8-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    curl \
    git \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Install Android SDK components (aligned with local ADB 36.0.0)
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Set working directory
WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Install Appium and drivers
RUN npx appium driver install uiautomator2

# Copy project files
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Expose Appium port
EXPOSE 4723

# Create necessary directories
RUN mkdir -p screenshots test-results logs

# Default command
CMD ["npm", "run", "appium"]