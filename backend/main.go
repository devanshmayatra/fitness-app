package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"
	"google.golang.org/api/option"
	"google.golang.org/api/sheets/v4"
	"google.golang.org/genai"
)

// Struct to parse Gemini's answer so we can save it
type CardioData struct {
	Duration string `json:"duration"`
	Distance string `json:"distance"`
	Calories string `json:"calories"`
}

type SheetRequest struct {
	TargetSheet string   `json:"target_sheet"` // e.g., "Logs", "Schedule", "Instructions"
	RowData     []string `json:"row_data"`
}

// 2. Data structures for Gemini AI interaction
type GeminiRequest struct {
	Contents []Content `json:"contents"`
}
type Content struct {
	Parts []Part `json:"parts"`
}
type Part struct {
	Text       string      `json:"text,omitempty"`
	InlineData *InlineData `json:"inlineData,omitempty"`
}
type InlineData struct {
	MimeType string `json:"mimeType"`
	Data     string `json:"data"`
}
type GeminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
}

var (
	PORT          string
	SpreadSheetID string
	GeminiApiKey  string
	CredsFile     string
	GeminiModel   = "gemini-2.5-flash"
)

func main() {

	_ = godotenv.Load()

	// 2. Load Variables from Environment
	PORT = os.Getenv("PORT")
	if PORT == "" {
		PORT = ":8080" // Default fallback
	}
	// Ensure port starts with ":" if it's just a number (Render often gives just "10000")
	if !strings.HasPrefix(PORT, ":") {
		PORT = ":" + PORT
	}

	SpreadSheetID = os.Getenv("SpreadSheetID")
	GeminiApiKey = os.Getenv("GeminiApiKey")
	CredsFile = os.Getenv("CredsFile")
	// GeminiApiUrl = os.Getenv("GeminiApiUrl")

	if SpreadSheetID == "" || GeminiApiKey == "" {
		log.Fatal("❌ CRITICAL ERROR: SPREADSHEET_ID or GEMINI_API_KEY is missing from environment variables!")
	}

	mux := http.NewServeMux()

	mux.HandleFunc("POST /submit", handleSubmit)
	mux.HandleFunc("POST /analyze-image", handleImageAnalysis)
	mux.HandleFunc("GET /data", handleGetData)
	// mux.HandleFunc("POST /seed-schedule", handleSeedSchedule)

	// Start Server
	fmt.Println("------------------------------------------------")
	fmt.Printf("🚀 Fitness Server running on port %s\n", PORT)
	fmt.Println("👉 /submit        -> Saves to Google Sheets")
	fmt.Println("👉 /analyze-image -> Sends photo to Gemini AI")
	fmt.Println("👉 /data          -> Retrieves data (Usage: /data?sheet=Logs)")
	fmt.Println("👉 /seed-schedule -> ONE-TIME SETUP: Populates the Schedule tab")
	fmt.Println("------------------------------------------------")

	server := &http.Server{
		Addr:    PORT,
		Handler: mux,
	}

	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}

}

func handleSubmit(w http.ResponseWriter, r *http.Request) {
	var req SheetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Use our new Helper Function
	err := saveToGoogleSheets(req.TargetSheet, req.RowData)
	if err != nil {
		log.Printf("Save Error: %v", err)
		http.Error(w, "Failed to save", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Saved Successfully"))
}

// --- 2. IMAGE ANALYSIS & AUTO-SAVE HANDLER ---
func handleImageAnalysis(w http.ResponseWriter, r *http.Request) {
	// A. Parse File
	r.ParseMultipartForm(10 << 20)
	file, _, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "No image found", http.StatusBadRequest)
		return
	}
	defer file.Close()

	imgBytes, err := io.ReadAll(file)
	if err != nil {
		http.Error(w, "Read error", http.StatusInternalServerError)
		return
	}
	// Note: We no longer Base64 encode here; we pass raw bytes to the SDK helper

	// B. Call AI
	resultJSON, err := callGemini(imgBytes)
	if err != nil {
		log.Printf("AI Error: %v", err)
		http.Error(w, "AI Error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// --- AUTO-SAVE LOGIC ---
	var cardio CardioData
	if err := json.Unmarshal([]byte(resultJSON), &cardio); err == nil {
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		rowToSave := []string{"Cardio", timestamp, "AI Scan", cardio.Duration, cardio.Distance, cardio.Calories}

		saveErr := saveToGoogleSheets("Logs", rowToSave)
		if saveErr != nil {
			fmt.Printf("⚠️ AI analysis worked, but Auto-Save failed: %v\n", saveErr)
		} else {
			fmt.Printf("✅ Auto-saved AI Cardio to Logs: %v\n", rowToSave)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(resultJSON))
}

func handleGetData(w http.ResponseWriter, r *http.Request) {
	// Get the target sheet from query parameter (e.g., /data?sheet=Schedule)
	targetSheet := r.URL.Query().Get("sheet")
	if targetSheet == "" {
		targetSheet = "Logs"
	}

	data, err := readFromGoogleSheets(targetSheet)
	if err != nil {
		log.Printf("Read Error: %v", err)
		http.Error(w, "Failed to read sheet", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{"data": data}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func handleSeedSchedule(w http.ResponseWriter, r *http.Request) {
	// Define the full schedule structure
	schedule := []struct {
		Day     string
		Title   string
		Details string
	}{
		{
			Day:     "Day 1",
			Title:   "Heavy Push (Chest Focus)",
			Details: "Chest (Big Muscle) × 5\n- Flat Barbell Bench Press (Heavy: 5-8 reps)\n- Incline Dumbbell Press\n- Weighted Dips (Leaning forward)\n- Pec Deck Flys\n- Cable Crossovers (Low to High)\n\nShoulders × 3\n- Front: Seated Dumbbell Overhead Press (Heavy)\n- Side: Dumbbell Lateral Raises\n- Side: Cable Lateral Raises (Behind the back)\n\nBiceps × 2\n- Barbell Curls (Heavy)\n- Hammer Curls",
		},
		{
			Day:     "Day 2",
			Title:   "Heavy Pull (Back Focus)",
			Details: "Back (Big Muscle) × 5\n- Deadlifts (or Rack Pulls)\n- Lat Pulldowns (Wide Grip)\n- Bent Over Barbell Rows\n- Seated Cable Rows (Close Grip)\n- Straight Arm Pulldowns (Rope)\n\nRear Delts × 2\n- Face Pulls\n- Reverse Pec Deck\n\nTriceps × 2\n- Rope Pushdowns\n- Overhead Cable Extensions",
		},
		{
			Day:     "Day 3",
			Title:   "Heavy Legs (Quad Focus)",
			Details: "Squats (Barbell or Smith Machine)\n- Leg Press (Heavy)\n- Leg Extensions\n- Standing Calf Raises",
		},
		{
			Day:     "Day 4",
			Title:   "Aesthetic Push (Shoulder Priority)",
			Details: "Chest (Maintenance) × 3\n- Incline Machine Press\n- Flat Dumbbell Press (Moderate weight, deep stretch)\n- Machine Flys\n\nShoulders (Focus) × 4\n- Side: Dumbbell Lateral Raises (Strict)\n- Side: Machine Lateral Raises (Drop set focus)\n- Front: Arnold Press (Rotational)\n- Front: Front Plate Raises (or Cable Front Raises)\n\nBiceps (Focus) × 3\n- Preacher Curls\n- Incline Dumbbell Curls\n- Concentration Curls",
		},
		{
			Day:     "Day 5",
			Title:   "Aesthetic Pull (Rear Delt Priority)",
			Details: "Back (Maintenance) × 3\n- Pull-Ups (or Assisted Machine)\n- Single Arm Dumbbell Rows\n- Chest-Supported Machine Row\n\nRear Delts (Focus) × 3\n- Face Pulls (High reps: 15-20)\n- Rear Delt Dumbbell Flys (Bent over)\n- Cable Reverse Flys (Cross body)\n\nTriceps (Focus) × 3\n- Skull Crushers (EZ Bar)\n- Tricep Dips (Bodyweight)\n- Single Arm Reverse Grip Pushdown",
		},
		{
			Day:     "Day 6",
			Title:   "Legs B (Posterior Chain)",
			Details: "Romanian Deadlifts (RDL) (Hamstrings/Glutes)\n- Lying Leg Curls\n- Walking Lunges\n- Seated Calf Raises",
		},
		{
			Day:     "Day 7",
			Title:   "Active Rest",
			Details: "Just the 1 Hour Morning Walk.",
		},
	}

	// Loop through and save each day
	for _, item := range schedule {
		// Row Format: [Day, Title, Details]
		row := []string{item.Day, item.Title, item.Details}
		err := saveToGoogleSheets("Schedule", row)
		if err != nil {
			http.Error(w, "Failed to save "+item.Day, http.StatusInternalServerError)
			return
		}
		// Small delay to prevent hitting Google's rate limits too hard
		time.Sleep(200 * time.Millisecond)
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("✅ Schedule Seeded Successfully into 'Schedule' tab!"))
	fmt.Println("✅ Seeded full schedule to Google Sheets.")
}

// --- HELPER: READ FROM SHEETS ---
func readFromGoogleSheets(targetSheet string) ([][]interface{}, error) {
	ctx := context.Background()
	srv, err := sheets.NewService(ctx, option.WithCredentialsFile(CredsFile))
	if err != nil {
		return nil, fmt.Errorf("auth error: %v", err)
	}

	rangeName := fmt.Sprintf("%s!A:Z", targetSheet)
	resp, err := srv.Spreadsheets.Values.Get(SpreadSheetID, rangeName).Do()
	if err != nil {
		return nil, err
	}

	return resp.Values, nil
}

func saveToGoogleSheets(targetSheet string, data []string) error {
	ctx := context.Background()
	srv, err := sheets.NewService(ctx, option.WithCredentialsFile(CredsFile))
	if err != nil {
		return fmt.Errorf("auth error: %v", err)
	}

	// Prepare data
	row := make([]interface{}, len(data))
	for i, v := range data {
		row[i] = v
	}

	if targetSheet == "" {
		targetSheet = "Logs"
	}

	rangeName := fmt.Sprintf("%s!A:Z", targetSheet)
	valueRange := &sheets.ValueRange{Values: [][]interface{}{row}}

	_, err = srv.Spreadsheets.Values.Append(SpreadSheetID, rangeName, valueRange).ValueInputOption("USER_ENTERED").Do()
	return err
}

func callGemini(imgBytes []byte) (string, error) {
	if GeminiApiKey == "" || strings.Contains(GeminiApiKey, "PASTE_YOUR") {
		return "", fmt.Errorf("API Key is missing/invalid")
	}

	ctx := context.Background()

	// 1. Initialize Client
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey: GeminiApiKey,
	})
	if err != nil {
		return "", fmt.Errorf("failed to create GenAI client: %v", err)
	}

	// 2. Prepare Prompt and Image
	prompt := `Analyze this treadmill/cardio screen. Extract:
	1. Duration (Time)
	2. Distance (km or miles)
	3. Calories
	Return ONLY a JSON object. No markdown.
	Format: {"duration": "xx:xx", "distance": "x.x", "calories": "xxx"}`

	// 3. Call the API using the correct structure
	// We wrap our Parts in a Content object
	resp, err := client.Models.GenerateContent(ctx, GeminiModel, []*genai.Content{
		{
			Parts: []*genai.Part{
				{
					Text: prompt,
				},
				{
					InlineData: &genai.Blob{
						MIMEType: "image/jpeg",
						Data:     imgBytes,
					},
				},
			},
		},
	}, nil)

	if err != nil {
		return "", fmt.Errorf("GenerateContent error: %v", err)
	}

	// 4. Extract Text using the helper method
	text := resp.Text()

	// Clean up markdown if present
	text = strings.ReplaceAll(text, "```json", "")
	text = strings.ReplaceAll(text, "```", "")
	return strings.TrimSpace(text), nil
}
