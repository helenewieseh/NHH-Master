# ==============================================================================
# Part 1 - Import necessary packages
# ==============================================================================

# Standard libraries
import os  # For file and environment variable management
from datetime import datetime, timedelta  # For working with dates and time intervals
from zoneinfo import ZoneInfo  # For timezone support

# GUI libraries
import tkinter as tk  # For GUI creation
from tkinter import ttk, scrolledtext  # For enhanced widgets like drop-downs and scrollable text boxes

# Azure and OpenAI libraries
from openai import AzureOpenAI  # For accessing Azure OpenAI APIs
from azure.storage.blob import BlobServiceClient  # For working with Azure Blob Storage

# Third-pary libraries
import yfinance as yf  # For fetching stock data
import talib  # For technical analysis of stock data (RSI, MACD, etc.)
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
connection_string = "add string here"
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


def gpt_prediction(final_prompt):
    """Fetch GPT prediction."""
    try:
        response = client.chat.completions.create(
            model="GPT4o-API",
            messages=[
                {"role": "system",
                  "content": "You are an expert at predicting stock price movement for Norwegian stocks based on sentiment in the news,"
                             "stock data, technical indicators and trends, with a focus on predicting short-term movements "},
                {"role": "user", "content": final_prompt}
            ],
            max_tokens=1800,
            temperature=0.3
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: Exception occurred during prediction: {str(e)}"

def prepare_final_prompt(symbol, event_metrics, pre_event_metrics, sector, market_cap, sentiment_response):
    """
    Prepare the final prompt for GPT based on the calculated metrics.
    """
    return (
        f"### Company Details ###\n"
        f"- **Sector**: {sector} (e.g., Technology, Energy, Healthcare, etc.)\n"
        f"- **Market Capitalization**: {market_cap:,} NOK\n\n"
        
        f"### Sentiment and Technical Analysis ###\n"
        f"- **Sentiment Analysis Summary**: {sentiment_response}\n\n"

        f"### event Day Metrics ###\n"
        f"- **Event Day Price Change**: {event_metrics['price_change']}% (Change from open to close on the event day)\n"
        f"- **Event Day Closing Price**: {event_metrics['closing_price']:.2f}NOK (Final price at market close on the event day)\n"
        f"- **Intraday Volatility (event Day)**: {event_metrics['volatility']:.2f}NOK (High - Low price range on the event day)\n"
        f"- **Event-Day Volume Spike**: {event_metrics['volume_spike']:.2f}% (Volume compared to 5-day average before event)\n\n"

        f"### Short-Term Technical Indicators ###\n"
        f"- **Pre-event 3-Day Moving Average**: {pre_event_metrics['three_day_ma']:.2f}NOK\n"
        f"(Calculated using data from 3 trading days prior to the event, ending with the closing price on the day before the event).\n"
        f"- **Pre-event 5-Day Price Momentum**: {pre_event_metrics['five_day_momentum']:.2f}%\n"
        f"(Momentum of price changes over the 5 trading days leading up to, but not including, the event day).\n"
        f"- **Pre-event ATR (3-Days)**: {pre_event_metrics['atr_three_day']:.2f}NOK\n"
        f"(Average True Range calculated over the 3 trading days prior to the event).\n"
        f"- **Pre-event 5-Day RSI**: {pre_event_metrics['rsi_5_value']:.2f} ({pre_event_metrics['rsi_5_status']})\n\n"
        f"(Relative Strength Index calculated for the 5 trading days leading up to, but not including, the event day.).\n\n"

        f"### Intermediate-Term Technical Indicators ###\n"
        f"- **Pre-event 20-Day Moving Average**: {pre_event_metrics['twenty_day_ma']:.2f}NOK\n"
        f"(Intermediate trend calculated using data from the 20 trading days prior to the event, ending with the closing price on the day before the event).\n"
        f"- **Pre-event 20-Day RSI**: {pre_event_metrics['rsi_20_value']:.2f} ({pre_event_metrics['rsi_20_status']})\n"
        f"(Relative Strength Index calculated for the 20 trading days leading up to, but not including, the event day.)\n"
        f"- **Pre-event MACD (12-26-9)**: {pre_event_metrics['macd_value']:.2f}, MACD Signal: {pre_event_metrics['macd_signal_value']:.2f} "
        f"({pre_event_metrics['macd_status']})\n"
        f"(Momentum and trend changes calculated using data up to, but not including, the event day).\n"

        f"### Prediction Task ###\n"
        f"Using the factors above, predict the stock price movement for {symbol} over the next 3 trading days. "
        f"This is defined as the percentage change from the event day's closing price to the closing price at the end of the third trading day.\n\n"

        f"### Classification Rules ###\n"
        f"- **Bullish**: Corresponding to a price increase of more than +2%.\n"
        f"- **Neutral**: Corresponding to a price change between -2% and +2% (inclusive).\n"
        f"- **Bearish**: Corresponding to a price decrease of more than -2%.\n\n"

        f"### Provide Prediction ###\n"
        f"Provide your prediction with a concise rationale, addressing the following:\n"
        f"- How sentiment analysis (based on financial news released on the event day) and event-day metrics support the prediction.\n"
        f"- How short-term indicators (calculated from data before the event day) reflect recent price behavior leading up to the event day.\n"
        f"- How intermediate-term indicators (calculated from data before the event day) provide broader context for the outlook.\n"
        f"- Consider the sector and market capitalization as context for expected volatility and behavior.\n"
        f"Note: The provided data stops at the event day. Your prediction should focus on post-event price movement starting from the closing price of the event day."
    )

def fetch_company_info(symbol, event_metrics):
    """
    Fetch and return company information including sector and market capitalization.
    """
    stock = yf.Ticker(symbol)
    info = stock.info

    sector = info.get("sector", "Unknown")
    shares_outstanding = info.get("sharesOutstanding", 0)
    market_cap = (
        event_metrics["closing_price"] * shares_outstanding if shares_outstanding else "Unavailable"
    )

    return sector, market_cap


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
                  "content": "You are an expert at analyzing the implications of sentiment strength, direction, and "
                             "relevance of financial news on stock prices, with a focus on predicting short-term movements for Norwegian stocks."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1000,
            temperature=0.3
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: Exception occurred during prediction: {str(e)}"

# ==============================================================================
# Part 4: Calculation functions
# ==============================================================================

def calculate_event_day_metrics(symbol, event_date_str, lookback_years=1):
    """
    Calculate metrics for the event day.
    """
    try:
        # Parse event date
        event_date = datetime.strptime(event_date_str, "%Y-%m-%d").replace(tzinfo=ZoneInfo("Europe/Oslo"))
        lookback_days = lookback_years * 365

        # Fetch historical stock data
        stock_data = yf.Ticker(symbol).history(
            start=(event_date - timedelta(days=lookback_days)).strftime("%Y-%m-%d"),
            end=(event_date + timedelta(days=20)).strftime("%Y-%m-%d")
        )

        # Validate if data is empty
        if stock_data.empty:
            raise ValueError(f"No data found for the symbol '{symbol}'. Please check the ticker symbol and try again.")

        stock_data.index = stock_data.index.tz_convert(ZoneInfo("Europe/Oslo"))

        if event_date not in stock_data.index:
            raise ValueError(f"The event date {event_date} is not a valid trading day.")

        # event day metrics
        metrics = {
            "closing_price": stock_data.loc[event_date, "Close"],
            "open_price": stock_data.loc[event_date, "Open"],
            "high_price": stock_data.loc[event_date, "High"],
            "low_price": stock_data.loc[event_date, "Low"],
            "volume": stock_data.loc[event_date, "Volume"],
            "price_change": round(
                ((stock_data.loc[event_date, "Close"] - stock_data.loc[event_date, "Open"]) /
                 stock_data.loc[event_date, "Open"]) * 100, 2
            ),
            "volatility": stock_data.loc[event_date, "High"] - stock_data.loc[event_date, "Low"],
            "stock_data": stock_data  # Include stock_data in the returned dictionary
        }

        # Pre-event data for volume analysis
        pre_event_data = stock_data.loc[stock_data.index < event_date]
        avg_volume_5d = pre_event_data["Volume"].rolling(window=5).mean().iloc[-1]
        metrics["volume_spike"] = round(
            ((metrics["volume"] - avg_volume_5d) / avg_volume_5d) * 100, 2
        )

        return metrics
    except Exception as e:
        raise ValueError(f"Error in event day calculations: {str(e)}")



def calculate_pre_event_data(stock_data, event_date):
    """
    Calculate pre-event data metrics for a given stock data and event date.
    """
    try:
        # Drop rows with missing 'Close' values
        stock_data = stock_data.dropna(subset=["Close"])

        # Ensure enough data for RSI calculation
        if len(stock_data) >= 5:
            stock_data["RSI_5"] = talib.RSI(stock_data["Close"], timeperiod=5)
            stock_data["RSI_20"] = talib.RSI(stock_data["Close"], timeperiod=20)
        else:
            raise ValueError("RSI_5 could not be calculated. Ensure sufficient data is available.")

        # Calculate MACD
        stock_data["MACD"], stock_data["MACD_signal"], _ = talib.MACD(
            stock_data["Close"], fastperiod=12, slowperiod=26, signalperiod=9
        )

        # Validate MACD calculation
        if stock_data["MACD"].isna().all() or stock_data["MACD_signal"].isna().all():
            raise ValueError("MACD could not be calculated. Ensure sufficient data is available.")

        # Calculate ATR
        stock_data["Previous_Close"] = stock_data["Close"].shift(1)
        stock_data["TR"] = stock_data.apply(
            lambda row: max(
                row["High"] - row["Low"],  # High - Low
                abs(row["High"] - row["Previous_Close"]),  # High - Previous Close
                abs(row["Low"] - row["Previous_Close"])  # Low - Previous Close
            ),
            axis=1
        )
        stock_data["ATR_3"] = stock_data["TR"].rolling(window=3).mean()

        # Validate ATR calculation
        if stock_data["ATR_3"].isna().all():
            raise ValueError("ATR_3 could not be calculated. Ensure sufficient data is available.")

        # Calculate Moving Averages
        stock_data["3_day_MA"] = stock_data["Close"].rolling(window=3).mean()
        stock_data["20_day_MA"] = stock_data["Close"].rolling(window=20).mean()

        # Validate Moving Averages
        if stock_data["3_day_MA"].isna().all():
            raise ValueError("3_day_MA could not be calculated. Ensure sufficient data is available.")
        if stock_data["20_day_MA"].isna().all():
            raise ValueError("20_day_MA could not be calculated. Ensure sufficient data is available.")

        # Calculate Momentum
        stock_data["5_day_momentum"] = (
            (stock_data["Close"] - stock_data["Close"].shift(5)) / stock_data["Close"].shift(5)
        ) * 100

        # Validate Momentum
        if stock_data["5_day_momentum"].isna().all():
            raise ValueError("5_day_momentum could not be calculated. Ensure sufficient data is available.")

        # Filter pre-event data
        pre_event_data = stock_data.loc[stock_data.index < event_date]

        if len(pre_event_data) < 20:
            raise ValueError("Not enough data for 20-day pre-event analysis.")

        # Tail subsets
        pre_event_20d = pre_event_data.tail(20)
        pre_event_10d = pre_event_data.tail(10)
        pre_event_5d = pre_event_data.tail(5)

        # Metrics dictionary aligned with prompt names
        metrics = {}

        # Volatility metrics
        metrics["pre_event_volatility_5d"] = pre_event_5d["High"].sub(pre_event_5d["Low"]).mean()
        metrics["pre_event_volatility_10d"] = pre_event_10d["High"].sub(pre_event_10d["Low"]).mean()

        # Price change percentages
        metrics["pre_event_change_5d"] = round(
            ((pre_event_5d["Close"].iloc[-1] - pre_event_5d["Close"].iloc[0]) /
             pre_event_5d["Close"].iloc[0]) * 100, 2)
        metrics["pre_event_change_10d"] = round(
            ((pre_event_10d["Close"].iloc[-1] - pre_event_10d["Close"].iloc[0]) /
             pre_event_10d["Close"].iloc[0]) * 100, 2)
        metrics["pre_event_change_20d"] = round(
            ((pre_event_20d["Close"].iloc[-1] - pre_event_20d["Close"].iloc[0]) /
             pre_event_20d["Close"].iloc[0]) * 100, 2)

        # Latest RSI, MACD, and Moving Averages values
        last_row = pre_event_data.iloc[-1]
        metrics["rsi_5_value"] = last_row["RSI_5"]
        metrics["rsi_20_value"] = last_row["RSI_20"]
        metrics["macd_value"] = last_row["MACD"]
        metrics["macd_signal_value"] = last_row["MACD_signal"]
        metrics["atr_three_day"] = last_row["ATR_3"]
        metrics["three_day_ma"] = last_row["3_day_MA"]
        metrics["twenty_day_ma"] = last_row["20_day_MA"]
        metrics["five_day_momentum"] = last_row["5_day_momentum"]

        # Determine RSI statuses
        metrics["rsi_5_status"] = (
            "Overbought" if metrics["rsi_5_value"] > 70
            else "Oversold" if metrics["rsi_5_value"] < 30
            else "Neutral"
        )
        metrics["rsi_20_status"] = (
            "Overbought" if metrics["rsi_20_value"] > 70
            else "Oversold" if metrics["rsi_20_value"] < 30
            else "Neutral"
        )

        # Determine MACD status
        metrics["macd_status"] = (
            "Bullish Crossover" if metrics["macd_value"] > metrics["macd_signal_value"]
            else "Bearish Crossover"
        )

        return metrics
    except Exception as e:
        raise ValueError(f"Error in pre-event data calculations: {str(e)}")


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


def display_data(chat_display, event_date_str, sector, market_cap, event_metrics, pre_event_metrics):
    """
    Display the company and stock data used in the prompt in the chat display.
    """
    chat_display.insert(
        tk.END,
        f"### Company Information ###\n"
        f"- Sector: {sector}\n"
        f"- Market Capitalization (on event date {event_date_str}): {market_cap} NOK\n\n"
    )
    chat_display.insert(
        tk.END,
        f"Stock Data:\n"
        f"- Event Day Price Change: {event_metrics['price_change']}%\n"
        f"- Event Day Closing Price: {event_metrics['closing_price']:.2f} NOK\n" 
        f"- Event-Day Volume Spike: {event_metrics['volume_spike']:.2f}%\n"
        f"- Event-Day Volatility: {event_metrics['volatility']:.2f} NOK\n"
        f"- Pre-event 3-Day Moving Average: {pre_event_metrics['three_day_ma']:.2f} NOK\n"
        f"- Pre-event 20-Day Moving Average: {pre_event_metrics['twenty_day_ma']:.2f} NOK\n"
        f"- Pre-event 5-Day Price Change: {pre_event_metrics['pre_event_change_5d']}%\n"
        f"- Pre-event 5-Day Price Momentum: {pre_event_metrics['five_day_momentum']:.2f}%\n"
        f"- Pre-event ATR (3-Day): {pre_event_metrics['atr_three_day']:.2f} NOK\n"
        f"- Pre-event 5-Day RSI: {pre_event_metrics['rsi_5_value']:.2f} ({pre_event_metrics['rsi_5_status']})\n"
        f"- Pre-event 20-Day RSI: {pre_event_metrics['rsi_20_value']:.2f} ({pre_event_metrics['rsi_20_status']})\n"
        f"- Pre-event MACD (12-26-9): {pre_event_metrics['macd_value']:.2f}, MACD Signal: {pre_event_metrics['macd_signal_value']:.2f} "
        f"({pre_event_metrics['macd_status']})\n\n"
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
            return None, None, None

        # Validate stock symbol
        symbol = self.symbol_entry.get().upper()
        if not symbol:
            self.chat_display.insert(tk.END, "Stock symbol is required. Please enter a valid symbol.\n\n")
            return None, None, None

        return event_date_str, event_date, symbol

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
        event_date_str, event_date, symbol = self.validate_inputs()
        if not event_date_str or not event_date or not symbol:
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

        # Analyze and display sentiment for the articles
        try:
            sentiment_response = analyze_sentiments_for_articles(articles)
            display_sentiment_analysis(self.chat_display, sentiment_response)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error analyzing sentiment: {str(e)}\n\n")
            return

        try:
            # Calculate event day metrics
            event_metrics = calculate_event_day_metrics(symbol, event_date_str)
            stock_data = event_metrics.pop("stock_data")
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error calculating event day metrics: {str(e)}\n\n")
            return

        try:
            # Calculate pre-event metrics
            pre_event_metrics = calculate_pre_event_data(stock_data, event_date)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error calculating pre-event metrics: {str(e)}\n\n")
            return

        try:
            # Fetch company information
            sector, market_cap = fetch_company_info(symbol, event_metrics)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error fetching company information: {str(e)}\n\n")
            return

        try:
            # Calculate post-event metrics
            post_event_metrics = calculate_post_event_metrics(symbol, event_date)

        except Exception as e:
            self.chat_display.insert(tk.END, f"Error calculating post-event metrics: {str(e)}\n\n")
            return


        try:
            # Prepare the GPT prompt
            final_prompt = prepare_final_prompt(
                symbol, event_metrics, pre_event_metrics, sector, market_cap, sentiment_response
            )
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error preparing the prompt: {str(e)}\n")
            return

        try:
            # Display data used in the prompt
            display_data(
                self.chat_display, event_date_str, sector, market_cap,
                event_metrics, pre_event_metrics
            )
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error displaying data: {str(e)}\n")
            return

        try:
            prediction = gpt_prediction(final_prompt)
            if "Error" in prediction:
                raise ValueError("GPT failed to generate a prediction.")
            self.chat_display.insert(tk.END, f"### Hybrid prediction ###\n{prediction}\n\n")
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error fetching prediction: {str(e)}\n")

        try:
            # Display post-event-day data for validation

            display_post_event_data(self.chat_display, post_event_metrics)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error displaying post-event data: {str(e)}\n")
            return




# ==============================================================================
# Part 8 - Run the GUI
# ==============================================================================
if __name__ == "__main__":
    root = tk.Tk()
    app = ChatbotGUI(master=root)
    root.mainloop()
