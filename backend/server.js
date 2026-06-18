require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Vocabulary Database by Level
const VOCABULARY_DB = {
  beginner: [
    { word: "apple", meaning_kh: "ផ្លែប៉ោម", example: "I eat an apple every day." },
    { word: "book", meaning_kh: "សៀវភៅ", example: "He is reading an interesting book." },
    { word: "cat", meaning_kh: "ឆ្មា", example: "The cat is sleeping on the sofa." },
    { word: "dog", meaning_kh: "ឆ្កែ", example: "My dog loves to run in the park." },
    { word: "water", meaning_kh: "ទឹក", example: "Please give me a glass of water." },
    { word: "school", meaning_kh: "សាលារៀន", example: "Children go to school to learn." },
    { word: "teacher", meaning_kh: "គ្រូបង្រៀន", example: "Our teacher is very kind and helpful." },
    { word: "house", meaning_kh: "ផ្ទះ", example: "They live in a beautiful house." },
    { word: "family", meaning_kh: "គ្រួសារ", example: "I love spending time with my family." },
    { word: "friend", meaning_kh: "មិត្តភក្តិ", example: "She is my best friend from childhood." },
    { word: "happy", meaning_kh: "សប្បាយរីករាយ", example: "The children were very happy today." },
    { word: "sad", meaning_kh: "កើតទុក្ខ/ព្រួយបារម្ភ", example: "Why do you look so sad?" },
    { word: "beautiful", meaning_kh: "ស្រស់ស្អាត", example: "Look at those beautiful flowers." },
    { word: "small", meaning_kh: "តូច", example: "This shirt is too small for me." },
    { word: "big", meaning_kh: "ធំ", example: "They have a big garden in the backyard." },
    { word: "run", meaning_kh: "រត់", example: "He can run very fast." },
    { word: "eat", meaning_kh: "ញ៉ាំ/ហូប", example: "We eat breakfast at 7:00 AM." },
    { word: "drink", meaning_kh: "ផឹក", example: "You should drink more water." },
    { word: "sleep", meaning_kh: "គេង", example: "Babies sleep for many hours." },
    { word: "cold", meaning_kh: "ត្រជាក់", example: "The winter here is very cold." },
    { word: "hot", meaning_kh: "ក្តៅ", example: "It is very hot outside today." },
    { word: "milk", meaning_kh: "ទឹកដោះគោ", example: "He drinks a glass of milk every night." },
    { word: "bread", meaning_kh: "នំបុ័ង", example: "I like to eat bread with butter." },
    { word: "car", meaning_kh: "ឡាន/រថយន្ត", example: "My father bought a new car." },
    { word: "sun", meaning_kh: "ព្រះអាទិត្យ", example: "The sun rises in the east." },
    { word: "moon", meaning_kh: "ព្រះច័ន្ទ", example: "The moon shines brightly at night." },
    { word: "star", meaning_kh: "ផ្កាយ", example: "We can see many stars in the sky." },
    { word: "tree", meaning_kh: "ដើមឈើ", example: "There is a big mango tree near our house." },
    { word: "flower", meaning_kh: "ផ្កា", example: "Rose is my favorite flower." },
    { word: "clock", meaning_kh: "នាឡិកា", example: "The clock on the wall shows 10 o'clock." }
  ],
  intermediate: [
    { word: "acquire", meaning_kh: "ទទួលបាន/រៀនបាន", example: "She managed to acquire a good command of English." },
    { word: "challenge", meaning_kh: "ការប្រឈម/បញ្ហាប្រឈម", example: "Learning a new language is a great challenge." },
    { word: "frequent", meaning_kh: "ញឹកញាប់", example: "He is a frequent visitor to our local library." },
    { word: "improve", meaning_kh: "កែលម្អ/ធ្វើឲ្យប្រសើរឡើង", example: "You need to practice daily to improve your speaking." },
    { word: "prepare", meaning_kh: "រៀបចំ", example: "The students are preparing for their final exams." },
    { word: "solution", meaning_kh: "ដំណោះស្រាយ", example: "We need to find a creative solution to this problem." },
    { word: "achieve", meaning_kh: "សម្រេចបាន", example: "She worked hard to achieve her goals." },
    { word: "benefit", meaning_kh: "អត្ថប្រយោជន៍", example: "Regular exercise has many health benefits." },
    { word: "conduct", meaning_kh: "ដឹកនាំ/ធ្វើ(ការស្រាវជ្រាវ)", example: "The scientists will conduct an experiment tomorrow." },
    { word: "develop", meaning_kh: "អភិវឌ្ឍ", example: "They plan to develop a new mobile application." },
    { word: "essential", meaning_kh: "ចាំបាច់/សារៈសំខាន់", example: "Water is essential for all living things." },
    { word: "flexible", meaning_kh: "បត់បែនបាន", example: "Our working hours are quite flexible." },
    { word: "maintain", meaning_kh: "រក្សាទុក/ថែរក្សា", example: "It is important to maintain a healthy lifestyle." },
    { word: "observe", meaning_kh: "សង្កេត", example: "Children learn by observing their parents." },
    { word: "prevent", meaning_kh: "បង្ការ/ទប់ស្កាត់", example: "Wearing seatbelts can prevent serious injuries." },
    { word: "require", meaning_kh: "តម្រូវឲ្យមាន", example: "This job requires good communication skills." },
    { word: "support", meaning_kh: "គាំទ្រ", example: "My friends always support my decisions." },
    { word: "value", meaning_kh: "តម្លៃ", example: "We must protect our traditional values." },
    { word: "various", meaning_kh: "ផ្សេងៗគ្នា/ចម្រុះ", example: "There are various ways to solve this math problem." },
    { word: "wonder", meaning_kh: "ឆ្ងល់/ងឿងឆ្ងល់", example: "I wonder why she didn't come to the party." },
    { word: "diligent", meaning_kh: "ឧស្សាហ៍ព្យាយាម", example: "She is a diligent student who always finishes her homework." },
    { word: "accurate", meaning_kh: "ត្រឹមត្រូវ/ឥតខ្ចោះ", example: "His description of the event was very accurate." },
    { word: "capable", meaning_kh: "មានសមត្ថភាព", example: "He is capable of doing much better work." },
    { word: "diverse", meaning_kh: "ចម្រុះ/ខុសៗគ្នា", example: "The city has a diverse population from all over the world." },
    { word: "efficient", meaning_kh: "មានប្រសិទ្ធភាព", example: "We need an efficient way to process these documents." },
    { word: "generate", meaning_kh: "បង្កើត/បង្កបង្កើត", example: "The new marketing strategy helped generate more sales." },
    { word: "hesitate", meaning_kh: "រារែក/ស្ទាក់ស្ទើរ", example: "Do not hesitate to ask if you have any questions." },
    { word: "influence", meaning_kh: "ឥទ្ធិពល", example: "My parents had a major influence on my career choice." },
    { word: "logical", meaning_kh: "មានហេតុផល/សមហេតុផល", example: "Her explanation was clear and logical." },
    { word: "motivate", meaning_kh: "លើកទឹកចិត្ត", example: "Good teachers know how to motivate their students." }
  ],
  advanced: [
    { word: "eloquent", meaning_kh: "វោហារកោសល្យ/ស្ទាត់ជំនាញក្នុងការនិយាយ", example: "She gave an eloquent speech that moved the entire audience." },
    { word: "resilient", meaning_kh: "ធន់/អាចស្តារឡើងវិញបានលឿន", example: "He remained resilient through all his business hardships." },
    { word: "ambiguous", meaning_kh: "ស្រពិចស្រពិល/មានន័យពីរផ្ទុយគ្នា", example: "The instructions were ambiguous, leaving us confused." },
    { word: "profound", meaning_kh: "ជ្រាលជ្រៅ/ធំធេង", example: "The book had a profound effect on my understanding of life." },
    { word: "meticulous", meaning_kh: "ផ្ចិតផ្ចង់/ហ្មត់ចត់បំផុត", example: "The research team was meticulous in collecting data." },
    { word: "pragmatic", meaning_kh: "ប្រាកដនិយម/អនុវត្តជាក់ស្តែង", example: "We need a pragmatic approach to solve this financial crisis." },
    { word: "ubiquitous", meaning_kh: "មាននៅគ្រប់ទីកន្លែង", example: "Smartphones are ubiquitous in modern society." },
    { word: "ephemeral", meaning_kh: "មិនស្ថិតស្ថេរ/កើតឡើងមួយភ្លែត", example: "Fame is often ephemeral, lasting only a short time." },
    { word: "superfluous", meaning_kh: "លើសលប់/មិនចាំបាច់", example: "Please delete any superfluous details from the report." },
    { word: "capricious", meaning_kh: "ប្រែប្រួលលឿន/ឆាប់ផ្លាស់ប្តូរចិត្ត", example: "The weather in the mountains can be highly capricious." },
    { word: "benevolent", meaning_kh: "សប្បុរស/ចិត្តធម៌", example: "A benevolent donor offered to pay for the new library." },
    { word: "dichotomy", meaning_kh: "ការបែងចែកជាពីរផ្ទុយគ្នា", example: "There is a strict dichotomy between public and private sectors." },
    { word: "substantiate", meaning_kh: "បញ្ជាក់/ផ្តល់ភស្តុតាងបញ្ជាក់", example: "You need to bring evidence to substantiate your claims." },
    { word: "reconcile", meaning_kh: "ផ្សះផ្សា/ធ្វើឲ្យស្របគ្នា", example: "It is hard to reconcile his statements with the facts." },
    { word: "quixotic", meaning_kh: "ឧត្តមគតិនិយមជ្រុល/មិនអាចទៅរួច", example: "His plan to build a space elevator was deemed quixotic." },
    { word: "cacophony", meaning_kh: "សំឡេងទ្រហឹងអឺងកង/សំឡេងមិនពីរោះ", example: "The busy market was filled with a loud cacophony of voices." },
    { word: "conundrum", meaning_kh: "ប្រស្នា/បញ្ហាស្មុគស្មាញរកនឹកមិនឃើញ", example: "How to reduce carbon emissions without stopping growth is a conundrum." },
    { word: "fastidious", meaning_kh: "ហ្មត់ចត់ជ្រុល/រើសអើងខ្លាំង", example: "He is fastidious about keeping his workspace perfectly clean." },
    { word: "gregarious", meaning_kh: "ចូលចិត្តសង្គម/ចូលចិត្តសេពគប់មិត្ត", example: "She is a gregarious person who loves going to parties." },
    { word: "indigenous", meaning_kh: "ជនជាតិដើម/ក្នុងស្រុក", example: "They are studying the customs of the indigenous people." },
    { word: "juxtaposition", meaning_kh: "ការដាក់ទន្ទឹមគ្នាដើម្បីប្រៀបធៀប", example: "The juxtaposition of the old temple and modern skyscraper was stunning." },
    { word: "lucrative", meaning_kh: "ដែលចំណេញច្រើន/កាក់កបខ្លាំង", example: "Real estate investment can be a highly lucrative business." },
    { word: "nefarious", meaning_kh: "ទុច្ចរិត/អាក្រក់ខ្លាំង", example: "The hacker had nefarious plans to steal banking details." },
    { word: "obsequious", meaning_kh: "ដែលបញ្ជោរ/អែបអប", example: "The waiters were obsequious, constantly bowing and smiling." },
    { word: "paradigmatic", meaning_kh: "ជាគំរូ/ជាឧទាហរណ៍ជាក់ស្តែង", example: "Her successful project is paradigmatic of what we want to achieve." },
    { word: "scrupulous", meaning_kh: "ទៀងត្រង់/មានសីលធម៌ខ្ពស់", example: "He is scrupulous about paying his taxes on time." },
    { word: "transient", meaning_kh: "បណ្តោះអាសន្ន/ឆ្លងកាត់", example: "The town has a transient population of tourists in summer." },
    { word: "venerable", meaning_kh: "ដែលគួរគោរពកោតក្រឡា/មានវ័យចាស់ទុំ", example: "The venerable monk gave a speech on peace and mindfulness." },
    { word: "wary", meaning_kh: "ប្រុងប្រយ័ត្ន/មិនសូវទុកចិត្ត", example: "Be wary of online deals that sound too good to be true." },
    { word: "zealous", meaning_kh: "មានចិត្តរំភើបខ្លាំង/ឧស្សាហ៍ខ្លាំង", example: "She is a zealous supporter of environmental conservation." }
  ]
};

// Helper function to fetch word details from DictionaryAPI.dev
async function fetchWordDetails(wordItem) {
  try {
    const res = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(wordItem.word)}`);
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && data.length > 0) {
        const entry = data[0];
        
        // Extract phonetic transcription
        const phonetic = entry.phonetic || (entry.phonetics && entry.phonetics.find(p => p.text)?.text) || '';
        
        // Extract audio url (US or UK pronunciation)
        const audioObj = entry.phonetics && entry.phonetics.find(p => p.audio && p.audio.startsWith('http'));
        const audio = audioObj ? audioObj.audio : '';
        
        // Extract definition and example
        let definition = '';
        let example = '';
        
        if (entry.meanings && entry.meanings.length > 0) {
          // Look for any definition containing example sentences
          for (const meaning of entry.meanings) {
            if (meaning.definitions && meaning.definitions.length > 0) {
              // Set default definition if none is found yet
              if (!definition) {
                definition = meaning.definitions[0].definition || '';
              }
              // Try to find a definition that has a real example sentence
              const defWithExample = meaning.definitions.find(d => d.example);
              if (defWithExample) {
                definition = defWithExample.definition || definition;
                example = defWithExample.example || '';
                break; // Found a good example, stop searching
              }
            }
          }
          // Fallback to first definition if no definition with example was found
          if (!definition && entry.meanings[0].definitions && entry.meanings[0].definitions.length > 0) {
            definition = entry.meanings[0].definitions[0].definition || '';
          }
        }
        
        return {
          word: wordItem.word,
          meaning_kh: wordItem.meaning_kh,
          phonetic: phonetic,
          audio: audio,
          definition: definition || 'No English definition found.',
          example: example || wordItem.example // Fallback to our local example if API doesn't have one
        };
      }
    }
  } catch (error) {
    console.error(`Error fetching word "${wordItem.word}":`, error.message);
  }
  
  // Fallback to local data if API call fails
  return {
    word: wordItem.word,
    meaning_kh: wordItem.meaning_kh,
    phonetic: '',
    audio: '',
    definition: 'Definition unavailable.',
    example: wordItem.example
  };
}

// GET /api/vocabulary?level=beginner&count=25
app.get('/api/vocabulary', async (req, res) => {
  const level = (req.query.level || 'beginner').toLowerCase();
  const count = parseInt(req.query.count, 10) || 25;

  const wordsList = VOCABULARY_DB[level] || VOCABULARY_DB['beginner'];

  // Shuffle array using Fisher-Yates algorithm
  const shuffled = [...wordsList];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }

  // Slice to count
  const selectedWords = shuffled.slice(0, count);

  // Fetch real API data for each word in parallel
  const enrichedWords = await Promise.all(
    selectedWords.map(wordItem => fetchWordDetails(wordItem))
  );

  res.json(enrichedWords);
});

// POST /api/chat
app.post('/api/chat', async (req, res) => {
  try {
    const { message, history } = req.body;
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

    // Map history to Gemini format: { role: "user" | "model", parts: [{ text: "..." }] }
    const contents = [];
    if (Array.isArray(history)) {
      history.forEach(msg => {
        if (msg.role && msg.text) {
          contents.push({
            role: msg.role === 'ai' ? 'model' : 'user',
            parts: [{ text: msg.text }]
          });
        }
      });
    }

    // Add current user message if it's not already in history
    contents.push({
      role: 'user',
      parts: [{ text: message }]
    });

    const systemInstruction = {
      parts: [{
        text: `You are an AI English Tutor. Help the user learn English (vocabulary, grammar, pronunciation, correction, translation, quizzes, sentence practice, and general conversation).

Handling Unrelated Questions:
- If the user asks about topics completely unrelated to learning English (such as coding/programming, math, general knowledge, science, etc.), politely explain that your main purpose is to act as their English tutor and specify what topics you can help them with.
- You must list the specific tasks you can help the user with:
  1. Vocabulary: Explain word meanings and provide Khmer translations.
  2. Grammar: Correct grammar mistakes and explain the rules clearly.
  3. Pronunciation: Guide the user on how to pronounce words.
  4. Sentence Practice: Provide sample sentences and practice writing.
  5. Quizzes: Generate multiple-choice questions to test their knowledge.
  6. Conversational Practice: Practice conversational English.

Formatting style:
- Use clear markdown, bolding (**bold**), bullet points, and emojis.
- Keep responses relatively brief and highly readable.
- If the user asks for vocabulary or meaning/explanation of a word, always provide a clear definition, sample sentences, AND its Khmer translation formatted like:
  Khmer: [translation here]
- If correcting grammar, display the correct sentence and briefly explain why:
  Correct sentence: "[corrected sentence]"
  Explanation: [brief explanation]
- If creating a quiz, format it with clear multiple-choice options (A, B, C, D) and explain the correct answer after the user replies.
- If the user starts a conversation (e.g. "Let's practice English"), engage in a natural, friendly chat, asking questions to keep the conversation going.`
      }]
    };

    const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_API_KEY
      },
      body: JSON.stringify({
        contents,
        systemInstruction
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('Gemini API Error:', errText);
      return res.status(response.status).json({ error: 'Failed to generate response from Gemini API', details: errText });
    }

    const data = await response.json();
    const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || 'No response generated.';
    
    res.json({ reply });
  } catch (err) {
    console.error('Chat endpoint error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Vocabulary Real-API Server is running on http://localhost:${PORT}`);
});


