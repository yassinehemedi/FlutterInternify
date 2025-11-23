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
app = FastAPI(title="Sentiment Analysis API")

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
    timeout=25.0
)

# Request model
class SentimentRequest(BaseModel):
    comment: str

# Response model
class SentimentResponse(BaseModel):
    comment: str
    sentiment: str
    processing_time: Optional[float] = None

# Core sentiment analysis function
def analyze_sentiment(comment: str) -> dict:
    start_time = time.time()

    prompt = f"""Analyze the sentiment of this comment:

Comment: "{comment}"

Sentiment Classification:
- "positive": Happy, satisfied, grateful, complimentary tone
  Examples: "Great job!", "I love this!", "Thank you so much", "Excellent service"

- "neutral": Factual, informative, questions, or no clear emotion
  Examples: "How does this work?", "I need information", "test", "hello"

- "negative": Angry, frustrated, disappointed, upset, critical tone
  Examples: "This is terrible", "I hate this", "Worst service ever", "Very disappointed"

Return ONLY valid JSON:
{{"sentiment": "positive|neutral|negative"}}"""

    try:
        print(f"🔍 Analyzing comment: {comment[:80]}...")
        print(f"⏰ Starting LLM call at {time.strftime('%H:%M:%S')}")

        completion = client.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "system", "content": "Sentiment analyst. Output JSON only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
            max_tokens=50,
            timeout=25
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
            sentiment_match = re.search(r'"sentiment"\s*:\s*"(positive|neutral|negative)"', text, re.IGNORECASE)

            result = {
                "sentiment": sentiment_match.group(1).lower() if sentiment_match else "neutral",
            }

        # Validate
        if result.get("sentiment") not in ["positive", "neutral", "negative"]:
            result["sentiment"] = "neutral"

        result["comment"] = comment
        result["processing_time"] = round(elapsed, 2)

        print(f"🎯 Result: sentiment={result['sentiment']}, time={elapsed:.2f}s")
        return result

    except Exception as e:
        elapsed = time.time() - start_time
        print(f"❌ Error after {elapsed:.2f}s: {e}")
        return {
            "comment": comment,
            "sentiment": "neutral",
            "processing_time": round(elapsed, 2),
        }

# FastAPI endpoint
@app.post("/analyze_sentiment", response_model=SentimentResponse)
def analyze_sentiment_endpoint(req: SentimentRequest):
    print(f"\n{'='*60}")
    print(f"📨 Received sentiment analysis request")
    print(f"📝 Comment: {req.comment[:100]}...")
    print(f"{'='*60}")

    result = analyze_sentiment(req.comment)

    print(f"📤 Sending response: {result}")
    print(f"{'='*60}\n")

    return result

# Health check
@app.get("/health")
def health_check():
    return {"status": "ok", "timestamp": time.time()}

# Root endpoint
@app.get("/")
def root():
    return {
        "message": "Sentiment Analysis API",
        "endpoints": {
            "analyze": "/analyze_sentiment (POST)",
            "health": "/health (GET)"
        }
    }