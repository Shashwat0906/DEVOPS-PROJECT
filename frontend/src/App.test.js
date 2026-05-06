import { render, screen, waitFor } from '@testing-library/react';
import App from './App';
import axios from 'axios';

jest.mock('axios');

test('renders TaskFlow title', async () => {
  axios.get.mockResolvedValue({ data: [{ id: 1, title: 'Test Task' }] });
  render(<App />);
  const linkElement = screen.getByText(/TaskFlow/i);
  expect(linkElement).toBeInTheDocument();
  
  await waitFor(() => {
    expect(screen.getByText('Test Task')).toBeInTheDocument();
  });
});
