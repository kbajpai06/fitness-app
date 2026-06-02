from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth
from app.api import users
from app.api import workout, diet, ai_coach, recovery, progress
from app.db.base import Base, engine
import app.models

app = FastAPI(title="AI Fitness App API", version="1.0.0")

Base.metadata.create_all(bind=engine)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(workout.router)
app.include_router(diet.router)
app.include_router(ai_coach.router)
app.include_router(recovery.router)
app.include_router(progress.router) 

@app.get("/")
def root():
    return {"status": "AI Fitness Backend Running 🚀"}
