# ==============================================================================
# Part 1 - Import necessary packages
# ==============================================================================

# Built-in libraries
import os  # For file and environment variable management
from datetime import datetime, timedelta  # For working with dates and time intervals
from zoneinfo import ZoneInfo  # For timezone support

# GUI libraries
import tkinter as tk  # For GUI creation
from tkinter import ttk, scrolledtext  # For enhanced widgets like drop-downs and scrollable text boxes

# OpenAI and Azure libraries
from openai import AzureOpenAI  # For accessing Azure OpenAI APIs
from azure.storage.blob import BlobServiceClient  # For working with Azure Blob Storage

# Financial libraries
import yfinance as yf  # For fetching stock data

# PDF processing
import fitz  # PyMuPDF for extracting text from PDFs

# ==============================================================================
# Part 2: Azure OpenAI Initialization
# ==============================================================================
os.environ["AZURE_OPENAI_API_KEY"] = "add key here"
os.environ["AZURE_OPENAI_ENDPOINT"] = "add endpoint here"
client = AzureOpenAI(api_key=os.getenv("AZURE_OPENAI_API_KEY"), api_version="2023-05-15",
                     azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"))

# ==============================================================================
# Part 3: Set up Blob Service Client
# ==============================================================================
connection_string == " write string here"
container_name = "chatbot-articles"
blob_service_client = BlobServiceClient.from_connection_string(connection_string)
container_client = blob_service_client.get_container_client(container_name)

# ==============================================================================
# Part 4: Utility Functions
# ==============================================================================

def download_pdf(blob_name):
    """Download a PDF from Azure Blob Storage and extract its text."""
    blob_client = container_client.get_blob_client(blob_name)
    pdf_content = blob_client.download_blob().readall()

    pdf_path = f'downloaded_{blob_name}'
    with open(pdf_path, 'wb') as pdf_file:
        pdf_file.write(pdf_content)

    return extract_text_from_pdf(pdf_path)


def extract_text_from_pdf(pdf_path):
    """Extract text from a downloaded PDF file."""
    text = ""
    with fitz.open(pdf_path) as doc:
        for page in doc:
            text += page.get_text()
    return text


def process_articles(selected_articles):
    """Download and extract text from the selected articles."""
    return {name: download_pdf(name) for name in selected_articles}


# ==============================================================================
# Part 5: Data Processing and Analysis
# ==============================================================================
def analyze_sentiments_for_articles(articles):
    """Analyze the sentiment of articles and return combined sentiment and summary."""
    combined_text = "\n\n".join([f"{name}: {text}" for name, text in articles.items()])
    categorization_rules = (
        "Categorization Rules for predicting stock price movement over the next 3 trading days "
        "(defined as the percentage change from the event day's closing price to the closing price at the end of the third trading day):\n"
        "- 'Bullish': Sentiment suggests a likely positive impact on the stock price over the next 3 days, reflecting optimism or strong investor interest "
        "(corresponding to a price increase of more than +2%).\n"
        "- 'Neutral': Sentiment suggests minimal or no significant impact on the stock price over the next 3 days, indicating either balanced opinions "
        "or low relevance to investors (price change between -2% and +2%, inclusive).\n"
        "- 'Bearish': Sentiment suggests a likely negative impact on the stock price over the next 3 days, driven by pessimism or potential concerns from investors "
        "(price decrease of more than -2%).\n\n"
    )
    prompt = (
        f"Analyze the sentiment strength, direction, and relevance of these articles that came out today on the event date. "
        f"Evaluate how the sentiment is likely to influence investor decisions and company's stock price movement over the next 3 trading days. "
        f"Classify the sentiment using the rules below and provide both classification and a brief summary of key points driving your classification:\n\n"
        f"{categorization_rules}\n{combined_text}"
    )

    try:
        response = client.chat.completions.create(
            model="GPT4o-API",
            messages=[
                {"role": "system",
                  "content": "You are an expert at analyzing the implications of sentiment strength, direction, and relevance of financial news on stock prices, with a focus on predicting short-term movements for Norwegian stocks."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1000,
            temperature=0.3
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: Exception occurred during prediction: {str(e)}"


def calculate_post_event_metrics(symbol, event_date):
    """
    Fetch stock data and calculate post-event metrics.
    """
    try:
        # Fetch only relevant stock data: event day + at least 3 trading days after
        stock_data = yf.Ticker(symbol).history(
            start=event_date.strftime("%Y-%m-%d"),
            end=(event_date + timedelta(days=7)).strftime("%Y-%m-%d")  # Buffer for non-trading days
        )

        # Validate if data is empty
        if stock_data.empty:
            raise ValueError(f"No data found for the symbol '{symbol}'. Please check the ticker symbol and try again.")


        # Convert time zone and validate data
        stock_data.index = stock_data.index.tz_convert(ZoneInfo("Europe/Oslo"))


        # Ensure event_date exists in stock_data
        if event_date not in stock_data.index:
            raise ValueError(f"The event date {event_date} is not a valid trading day.")

        # Extract event day closing price
        event_day_close = stock_data.loc[event_date, 'Close']

        # Extract the 3rd trading day's closing price
        post_event_data = stock_data.loc[stock_data.index > event_date]
        post_event_3d = post_event_data.head(3)
        if len(post_event_3d) < 3:
            return {
                "post_event_change_3d": "N/A",
                "post_event_3rd_day_close": "N/A",
            }

        post_event_change_3d = round(
            ((post_event_3d['Close'].iloc[-1] - event_day_close) / event_day_close) * 100, 2
        )
        post_event_3rd_day_close = post_event_3d['Close'].iloc[-1]

        return {
            "post_event_change_3d": post_event_change_3d,
            "post_event_3rd_day_close": post_event_3rd_day_close,
        }

    except Exception as e:
        raise ValueError(f"Error calculating post-event metrics: {str(e)}")



# ==============================================================================
# Part 6: Display Functions
# ==============================================================================
def display_sentiment_analysis(chat_display, sentiment_response):
    """Display the sentiment analysis results in the chat display."""
    chat_display.insert(
        tk.END,
        f"### Sentiment Analysis ###\n{sentiment_response}\n\n"
    )


def display_post_event_data(chat_display, post_event_metrics):
    """
    Display the post-event metrics in the chat display.
    """
    chat_display.insert(
        tk.END,
        f"### Post-event Data ###\n(for validation)\n"
        f"- 3-Day Closing Price: {post_event_metrics['post_event_3rd_day_close'] if post_event_metrics['post_event_3rd_day_close'] != 'N/A' else 'Not available'} NOK\n"
        f"- 3-Day Post-event Price Change: {post_event_metrics['post_event_change_3d'] if post_event_metrics['post_event_change_3d'] != 'N/A' else 'Not enough data'}%\n\n"
    )


# ==============================================================================
# Part 7: Chatbot GUI Class
# ==============================================================================

class ChatbotGUI:
    def __init__(self, master):
        """Initialize the GUI components and attach them to the master window."""
        self.master = master
        master.title("Sentiment and Stock Price Chatbot")
        master.geometry("800x600")
        master.resizable(True, True)

        self.create_widgets()
        self.load_blob_names()

    # -------------------------------------------------------------------------
    # GUI Setup Functions
    # -------------------------------------------------------------------------
    def create_widgets(self):
        """Create input fields and buttons for the chatbot interface."""
        ttk.Label(self.master, text="Select articles for sentiment analysis (hold Ctrl to select multiple):").pack(
            pady=5)

        # Drop-down menu for selecting multiple articles
        self.article_listbox = tk.Listbox(self.master, selectmode=tk.MULTIPLE, width=50)
        self.article_listbox.pack(pady=5)

        # Input field for stock ticker symbol
        ttk.Label(self.master, text="Enter stock symbol (e.g., DNB.OL):").pack(pady=5)
        self.symbol_entry = ttk.Entry(self.master, width=50)
        self.symbol_entry.pack(pady=5)

        # Input field for event date
        ttk.Label(self.master, text="Enter event date (YYYY-MM-DD):").pack(pady=5)
        self.event_date_entry = ttk.Entry(self.master, width=50)
        self.event_date_entry.pack(pady=5)

        # Button to submit the query
        ttk.Button(self.master, text="Analyze", command=self.analyze).pack(pady=10)

        # Scrollable text box for displaying the result
        self.chat_display = scrolledtext.ScrolledText(self.master, wrap=tk.WORD, width=80, height=20)
        self.chat_display.pack(padx=10, pady=10, expand=True, fill=tk.BOTH)

    def load_blob_names(self):
        """Load available reports from the blob container."""
        available_blobs = container_client.list_blobs()
        for blob in available_blobs:
            self.article_listbox.insert(tk.END, blob.name)  # Add article names to the listbox

    # -------------------------------------------------------------------------
    # Helper Functions
    # -------------------------------------------------------------------------
    def validate_inputs(self):
        """
        Validate user inputs for event date and stock symbol.
        """
        # Validate event date
        event_date_str = self.event_date_entry.get()
        try:
            event_date = datetime.strptime(event_date_str, "%Y-%m-%d").replace(tzinfo=ZoneInfo("Europe/Oslo"))
        except ValueError:
            self.chat_display.insert(tk.END, "Invalid date format. Please enter the date as YYYY-MM-DD.\n\n")
            return None, None

        # Validate stock symbol
        symbol = self.symbol_entry.get().upper()
        if not symbol:
            self.chat_display.insert(tk.END, "Stock symbol is required. Please enter a valid symbol.\n\n")
            return None, None

        return event_date, symbol

    def get_selected_articles(self):
        """Retrieve selected articles from the UI listbox."""
        selected_indices = self.article_listbox.curselection()
        return [self.article_listbox.get(i) for i in selected_indices]

    # -------------------------------------------------------------------------
    # Main Analyze Function
    # -------------------------------------------------------------------------
    def analyze(self):
        """Handle the user's query and fetch the appropriate data for analysis."""
        # Validate inputs
        event_date, symbol = self.validate_inputs()
        if not event_date or not symbol:
            return  # Exit if validation fails

        # Retrieve and process selected articles
        selected_articles = self.get_selected_articles()
        if not selected_articles:
            self.chat_display.insert(tk.END, "No articles selected. Please choose at least one article.\n\n")
            return

        try:
            articles = process_articles(selected_articles)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error processing articles: {str(e)}\n\n")
            return

        # Analyze sentiment for the articles
        try:
            sentiment_response = analyze_sentiments_for_articles(articles)
            display_sentiment_analysis(self.chat_display, sentiment_response)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error analyzing sentiment: {str(e)}\n\n")
            return

        # Calculate and display post-event metrics
        try:
            post_event_metrics = calculate_post_event_metrics(symbol, event_date)
            display_post_event_data(self.chat_display, post_event_metrics)
        except ValueError as e:
            self.chat_display.insert(tk.END, f"{str(e)}\n\n")
        except Exception as e:
            self.chat_display.insert(tk.END, f"An unexpected error occurred: {str(e)}\n\n")


# ==============================================================================
# Part 8 - Run the GUI
# ==============================================================================
if __name__ == "__main__":
    root = tk.Tk()
    app = ChatbotGUI(master=root)
    root.mainloop()
