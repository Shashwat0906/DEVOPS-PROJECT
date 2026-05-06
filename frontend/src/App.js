import { useEffect, useState } from "react";
import axios from "axios";
const BASE_URL = process.env.REACT_APP_API_URL || "http://localhost:5001";
function App() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");

  const fetchTasks = async () => {
    const res = await axios.get(`${BASE_URL}/tasks`);
    setTasks(res.data);
  };
  
  const addTask = async () => {
    await axios.post(`${BASE_URL}/tasks`, { title });
    fetchTasks();
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  return (
    <div>
      <h1>TaskFlow</h1>
      <input onChange={(e) => setTitle(e.target.value)} />
      <button onClick={addTask}>Add</button>

      {tasks.map((t) => (
        <div key={t.id}>{t.title}</div>
      ))}
    </div>
  );
}

export default App;