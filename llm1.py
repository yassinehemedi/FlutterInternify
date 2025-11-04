import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import OpenAI
import re
import json
import time
from typing import Optional
from dotenv import load_dotenv

# FastAPI app
app = FastAPI(title="Reclamation Priority API")

# OpenAI client
load_dotenv(dotenv_path="AI.env")

endpoint = "https://elboniai.services.ai.azure.com/openai/v1/"
deployment_name = "Llama-3.3-70B-Instruct"
api_key = os.getenv("OPENAI_API_KEY")

if not api_key:
    raise ValueError("Missing OPENAI_API_KEY environment variable")

client = OpenAI(
    base_url=endpoint,
    api_key=api_key,
    timeout=25.0  # ⬅️ Add timeout for OpenAI client
)

# Request model
class PriorityRequest(BaseModel):
    description: str

# Response model
class PriorityResponse(BaseModel):
    description: str
    priority: str
    sentiment: str
    processing_time: Optional[float] = None  # ⬅️ Track speed

# Core classification function
def classify_priority(description: str) -> dict:
    start_time = time.time()

    prompt = f"""Analyze this customer complaint and classify:

Complaint: "{description}"

Return:
- priority: "high" (urgent: account issues, payment, security, harassment) | "medium" (bugs, features) | "low" (feedback, questions)
- sentiment: "negative" (angry/frustrated) | "neutral" (factual) | "positive" (happy/satisfied)

JSON only:
{{"priority": "...", "sentiment": "..."}}"""

    try:
        print(f"🔍 Analyzing: {description[:80]}...")
        print(f"⏰ Starting LLM call at {time.strftime('%H:%M:%S')}")

        completion = client.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "system", "content": "Customer service analyst. Output JSON only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
            max_tokens=100,
            timeout=25  # ⬅️ Add explicit timeout
        )

        elapsed = time.time() - start_time
        print(f"✅ LLM responded in {elapsed:.2f}s")

        text = completion.choices[0].message.content.strip()
        print(f"📝 Response: {text}")

        # Clean markdown
        text = re.sub(r"```json\s*|\s*```", "", text, flags=re.IGNORECASE).strip()

        # Parse JSON
        try:
            result = json.loads(text)
        except json.JSONDecodeError:
            print(f"⚠️ Parse failed, using regex")
            priority_match = re.search(r'"priority"\s*:\s*"(high|medium|low)"', text, re.IGNORECASE)
            sentiment_match = re.search(r'"sentiment"\s*:\s*"(positive|neutral|negative)"', text, re.IGNORECASE)

            result = {
                "priority": priority_match.group(1).lower() if priority_match else "medium",
                "sentiment": sentiment_match.group(1).lower() if sentiment_match else "neutral",
            }

        # Validate
        if result.get("priority") not in ["high", "medium", "low"]:
            result["priority"] = "medium"
        if result.get("sentiment") not in ["positive", "neutral", "negative"]:
            result["sentiment"] = "neutral"

        result["description"] = description
        result["processing_time"] = round(elapsed, 2)

        print(f"🎯 Result: priority={result['priority']}, sentiment={result['sentiment']}, time={elapsed:.2f}s")
        return result

    except Exception as e:
        elapsed = time.time() - start_time
        print(f"❌ Error after {elapsed:.2f}s: {e}")
        return {
            "description": description,
            "priority": "medium",
            "sentiment": "neutral",
            "processing_time": round(elapsed, 2),
        }

# FastAPI endpoint
@app.post("/analyze_priority", response_model=PriorityResponse)
def analyze_priority_endpoint(req: PriorityRequest):
    print(f"\n{'='*60}")
    print(f"📨 Received request from client")
    print(f"📝 Text: {req.description[:100]}...")
    print(f"{'='*60}")

    result = classify_priority(req.description)

    print(f"📤 Sending response: {result}")
    print(f"{'='*60}\n")

    return result

# Health check
@app.get("/health")
def health_check():
    return {"status": "ok", "timestamp": time.time()}