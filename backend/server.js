const express = require("express");
const cors = require("cors");

const app = express();

// ✅ Explicit CORS config (important)
app.use(
  cors({
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST", "DELETE", "PUT", "PATCH", "OPTIONS"],
    allowedHeaders: "*",
  }),
);

app.use(express.json());

const taskRoutes = require("./routes/taskRoutes");
app.use("/tasks", taskRoutes);

app.get("/", (req, res) => {
  res.send("API Running");
});

module.exports = app;
