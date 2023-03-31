import "./App.css";
import { useState, useEffect } from "react";

import AppBar from "@mui/material/AppBar";
import Box from "@mui/material/Box";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";
import MenuIcon from "@mui/icons-material/Menu";
import { Container } from "@mui/system";
import { Card } from "@mui/material";
import CardContent from "@mui/material/CardContent";
import TextField from "@mui/material/TextField";

function App() {
  const [text, setText] = useState("");
  const [results, setResults] = useState([]);

  useEffect(() => {
    (async () => {
      const fetchedResults = await fetch("/api/read");
      const data = await fetchedResults.json();
      setResults(data);
    })();
    return () => {};
  }, []);

  const handleTextChange = (event) => {
    setText(event.target.value);
  };

  const handleSaveClick = async () => {
    if (text.trim()) {
      await fetch("/api/write", {
        method: "POST",
        headers: { "Content-Type": "text/plain" },
        body: text,
      });

      setResults((oldResults) => [...oldResults, { name: text }]);
      setText("");
    }
  };

  return (
    <>
      <Box sx={{ flexGrow: 1 }}>
        <AppBar position="static">
          <Toolbar>
            <IconButton
              size="large"
              edge="start"
              color="inherit"
              aria-label="menu"
              sx={{ mr: 2 }}
            >
              <MenuIcon />
            </IconButton>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              Dapprio, Inc.
            </Typography>
            <Button color="inherit">Login</Button>
          </Toolbar>
        </AppBar>
        <Box sx={{ display: "flex", justifyContent: "center", p: 1, m: 1 }}>
          <TextField
            id="item-input"
            value={text}
            onChange={handleTextChange}
            label="Text"
            variant="outlined"
            sx={{ marginRight: 2 }}
          />
          <Button onClick={handleSaveClick} variant="contained">
            Save
          </Button>
        </Box>
        <Container sx={{ display: "flex", flexWrap: "wrap", p: 1, m: 1 }}>
          {results.map(({ id, name }) => (
            <Card key={id} sx={{ maxWidth: 275, margin: 5 }}>
              <CardContent>
                <Typography
                  sx={{ fontSize: 14 }}
                  color="text.secondary"
                  gutterBottom
                >
                  {name}
                </Typography>
              </CardContent>
            </Card>
          ))}
        </Container>
      </Box>
    </>
  );
}

export default App;
