import logo from './logo.svg';
import './App.css';
import { useState, useEffect } from 'react'

function App() {
  const API_HOST = process.env.REACT_APP_API_HOST || '';
  const [text, setText] = useState('');

  useEffect(() => {
    (async () => {
      const result = await fetch(`${API_HOST}/api/`);
      const resultText = await result.text()
      setText(resultText);
    })();
    return () => { }
  }, [text]);

  return (
    <div className="App">
      <header className="App-header">
        <p>
          {text}
        </p>
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
