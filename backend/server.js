import express from 'express';
import multer from 'multer';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import {sendNotification} from './notification_controller.js';

const app = express();
app.use(cors());
app.use(express.json());

const uploadDir = path.join(path.resolve(), 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

app.use('/uploads', express.static(uploadDir));

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + path.extname(file.originalname);
    cb(null, uniqueSuffix);
  },
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    console.log('File details:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      extname: path.extname(file.originalname).toLowerCase()
    });
    const filetypes = /jpeg|jpg|png|gif/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype.split('/').pop());
    if (extname || mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only images are allowed!'));
    }
  },
});

app.post('/upload', upload.single('image'), (req, res) => {
  console.log('Received upload request');
  if (!req.file) {
    console.log('No file uploaded');
    return res.status(400).json({ error: 'No file uploaded' });
  }
  // const url = `http://10.0.2.2:3000/uploads/${req.file.filename}`;
  const url = `http://192.168.137.1:3000/uploads/${req.file.filename}`;
  console.log('File saved to:', req.file.path);
  res.json({ url });
});

app.use((err, req, res, next) => {
  console.error('Server error:', err.message);
  res.status(500).json({ error: err.message });
});

app.post('/send-notification', async (req, res) => {
  const { token, title, body } = req.body;

  if (!token || !title || !body) {
    return res.status(400).json({ error: 'token, title, and body are required' });
  }

  try {
    const response = await sendNotification(token, title, body);
    res.json({ success: true, response });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete images
app.post('/delete', (req, res) => {
  const { url } = req.body;

  if (!url) {
    return res.status(400).json({ error: 'URL is required' });
  }

  const filename = path.basename(url); // Extract file name from URL
  const filePath = path.join(uploadDir, filename);

  fs.unlink(filePath, (err) => {
    if (err) {
      console.error('Error deleting file:', err.message);
      return res.status(500).json({ error: 'Failed to delete image' });
    }

    console.log(`Deleted image: ${filePath}`);
    res.json({ success: true });
  });
});


app.listen(3000, '0.0.0.0', () => console.log('Server running on port 3000'));