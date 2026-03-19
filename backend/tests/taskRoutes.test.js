/* global describe, it, expect */
const request = require("supertest");
const app = require("../server");

describe("Task Routes", () => {
  it("should get starting tasks", async () => {
    const res = await request(app).get("/tasks");
    expect(res.statusCode).toEqual(200);
    expect(res.body).toEqual([]);
  });

  it("should create a new task", async () => {
    const res = await request(app).post("/tasks").send({ title: "Test Task" });
    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty("id");
    expect(res.body.title).toEqual("Test Task");
  });

  it("should delete a task", async () => {
    let res = await request(app)
      .post("/tasks")
      .send({ title: "Task to Delete" });
    const taskId = res.body.id;

    res = await request(app).delete(`/tasks/${taskId}`);
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toEqual("Deleted");
  });
});
