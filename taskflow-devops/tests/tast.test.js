const request = require("supertest");
const app = require("../server");

describe("Task API", () => {
  it("should create a task", async () => {
    const res = await request(app)
      .post("/tasks")
      .send({ title: "Test Task" });

    expect(res.statusCode).toBe(201);
    expect(res.body.title).toBe("Test Task");
  });

  it("should get tasks", async () => {
    const res = await request(app).get("/tasks");
    expect(res.statusCode).toBe(200);
  });
});