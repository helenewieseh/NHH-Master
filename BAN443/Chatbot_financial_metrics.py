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

# Financial libraries
import yfinance as yf  # For fetching stock data
import talib  # For technical analysis of stock data (RSI, MACD, etc.)

# ==============================================================================
# Part 2: Azure OpenAI Initialization
# ==============================================================================

os.environ["AZURE_OPENAI_API_KEY"] = "b08434afe34a4b4a96caec0bc074338a"
os.environ["AZURE_OPENAI_ENDPOINT"] = "https://gpt-ban443-2.openai.azure.com/openai/deployments/Group03/chat/completions?api-version=2023-03-15-preview"

client = AzureOpenAI(api_key=os.getenv("AZURE_OPENAI_API_KEY"), api_version="2023-05-15",
                     azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"))

# ==============================================================================
# Part 3: Utility functions
# ==============================================================================

def gpt_prediction(final_prompt):
    """Fetch GPT prediction."""
    try:
        response = client.chat.completions.create(
            model="GPT4o-API",
            messages=[
                {"role": "system",
                 "content": "You are an expert at predicting stock price movement for Norwegian stocks based on stock data, "
                            "technical indicators and trends, with a focus on predicting short-term movements"},
                {"role": "user", "content": final_prompt}
            ],
            max_tokens=1800,
            temperature=0.3
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: Exception occurred during prediction: {str(e)}"

def prepare_final_prompt(symbol, reference_metrics, pre_reference_metrics, sector, market_cap):
    """
    Prepare the final prompt for GPT based on the calculated metrics.
    """
    return (
        f"### Company Details ###\n"
        f"- **Sector**: {sector} (e.g., Technology, Energy, Healthcare, etc.)\n"
        f"- **Market Capitalization**: {market_cap:,} NOK\n\n"

        f"### Reference Day Metrics ###\n"
        f"- **Reference Day Price Change**: {reference_metrics['price_change']}% (Change from open to close on the reference day)\n"
        f"- **Reference Day Closing Price**: {reference_metrics['closing_price']:.2f}NOK (Final price at market close on the reference day)\n"
        f"- **Intraday Volatility (Reference Day**): {reference_metrics['volatility']:.2f}NOK (High - Low price range on the reference day)\n"
        f"- **Reference-Day Volume Spike**: {reference_metrics['volume_spike']:.2f}% (Volume compared to 5-day average before reference)\n\n"

        f"### Short-Term Technical Indicators ###\n"
        f"- **Pre-reference 3-Day Moving Average**: {pre_reference_metrics['three_day_ma']:.2f}NOK\n"
        f"(Calculated using data from 3 trading days prior to the reference, ending with the closing price on the day before the reference).\n"
        f"- **Pre-reference 5-Day Price Momentum**: {pre_reference_metrics['five_day_momentum']:.2f}%\n"
        f"(Momentum of price changes over the 5 trading days leading up to, but not including, the reference day).\n"
        f"- **Pre-reference ATR (3-Days)**: {pre_reference_metrics['atr_three_day']:.2f}NOK\n"
        f"(Average True Range calculated over the 3 trading days prior to the reference).\n"
        f"- **Pre-reference 5-Day RSI**: {pre_reference_metrics['rsi_5_value']:.2f} ({pre_reference_metrics['rsi_5_status']})\n\n"
        f"(Relative Strength Index calculated for the 5 trading days leading up to, but not including, the reference day).\n\n"

        f"### Intermediate-Term Technical Indicators ###\n"
        f"- **Pre-reference 20-Day Moving Average**: {pre_reference_metrics['twenty_day_ma']:.2f}NOK\n"
        f"(Intermediate trend calculated using data from the 20 trading days prior to the reference, ending with the closing price on the day before the reference).\n"
        f"- **Pre-reference 20-Day RSI**: {pre_reference_metrics['rsi_20_value']:.2f} ({pre_reference_metrics['rsi_20_status']})\n"
        f"(Relative Strength Index calculated for the 20 trading days leading up to, but not including, the reference day).\n"
        f"- **Pre-reference MACD (12-26-9)**: {pre_reference_metrics['macd_value']:.2f}, MACD Signal: {pre_reference_metrics['macd_signal_value']:.2f} "
        f"({pre_reference_metrics['macd_status']})\n"
        f"(Momentum and trend changes calculated using data up to, but not including, the reference day).\n"

        f"### Prediction Task ###\n"
        f"Using the factors above, predict the stock price movement for {symbol} over the next 3 trading days. "
        f"This is defined as the percentage change from the reference day's closing price to the closing price at the end of the third trading day.\n\n"

        f"### Classification Rules ###\n"
        f"- **Bullish**: Corresponding to a price increase of more than +2%.\n"
        f"- **Neutral**: Corresponding to a price change between -2% and +2% (inclusive).\n"
        f"- **Bearish**: Corresponding to a price decrease of more than -2%.\n\n"

        f"### Provide Prediction ###\n"
        f"Provide your prediction with a concise rationale, addressing the following:\n"
        f"- How reference-day metrics support the prediction.\n"
        f"- How short-term indicators (calculated from data before the reference day) reflect recent price behavior leading up to the reference day.\n"
        f"- How intermediate-term indicators (calculated from data before the reference day) provide broader context for the outlook.\n"
        f"- Consider the sector and market capitalization as context for expected volatility and behavior.\n"
        f"Note: The provided data stops at the reference day. Your prediction should focus on post-reference price movement starting from the closing price of the reference day."
    )

def fetch_company_info(symbol, reference_metrics):
    """
    Fetch and return company information including sector and market capitalization.
    """
    stock = yf.Ticker(symbol)
    info = stock.info

    sector = info.get("sector", "Unknown")
    shares_outstanding = info.get("sharesOutstanding", 0)
    market_cap = (
        reference_metrics["closing_price"] * shares_outstanding if shares_outstanding else "Unavailable"
    )

    return sector, market_cap

# ==============================================================================
# Part 4: Calculation functions
# ==============================================================================

def calculate_reference_day_metrics(symbol, reference_date_str, lookback_years=1):
    """
    Calculate metrics for the reference day.
    """
    try:
        # Parse reference date
        reference_date = datetime.strptime(reference_date_str, "%Y-%m-%d").replace(tzinfo=ZoneInfo("Europe/Oslo"))
        lookback_days = lookback_years * 365

        # Fetch historical stock data
        stock_data = yf.Ticker(symbol).history(
            start=(reference_date - timedelta(days=lookback_days)).strftime("%Y-%m-%d"),
            end=(reference_date + timedelta(days=20)).strftime("%Y-%m-%d")
        )

        # Validate if data is empty
        if stock_data.empty:
            raise ValueError(f"No data found for the symbol '{symbol}'. Please check the ticker symbol and try again.")

        stock_data.index = stock_data.index.tz_convert(ZoneInfo("Europe/Oslo"))

        if reference_date not in stock_data.index:
            raise ValueError(f"The reference date {reference_date} is not a valid trading day.")

        # Reference day metrics
        metrics = {
            "closing_price": stock_data.loc[reference_date, "Close"],
            "open_price": stock_data.loc[reference_date, "Open"],
            "high_price": stock_data.loc[reference_date, "High"],
            "low_price": stock_data.loc[reference_date, "Low"],
            "volume": stock_data.loc[reference_date, "Volume"],
            "price_change": round(
                ((stock_data.loc[reference_date, "Close"] - stock_data.loc[reference_date, "Open"]) /
                 stock_data.loc[reference_date, "Open"]) * 100, 2
            ),
            "volatility": stock_data.loc[reference_date, "High"] - stock_data.loc[reference_date, "Low"],
            "stock_data": stock_data  # Include stock_data in the returned dictionary
        }

        # Pre-reference data for volume analysis
        pre_reference_data = stock_data.loc[stock_data.index < reference_date]
        avg_volume_5d = pre_reference_data["Volume"].rolling(window=5).mean().iloc[-1]
        metrics["volume_spike"] = round(
            ((metrics["volume"] - avg_volume_5d) / avg_volume_5d) * 100, 2
        )

        return metrics
    except Exception as e:
        raise ValueError(f"Error in reference day calculations: {str(e)}")



def calculate_pre_reference_data(stock_data, reference_date):
    """
    Calculate pre-reference data metrics for a given stock data and reference date.
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

        # Filter pre-reference data
        pre_reference_data = stock_data.loc[stock_data.index < reference_date]

        if len(pre_reference_data) < 20:
            raise ValueError("Not enough data for 20-day pre-reference analysis.")

        # Tail subsets
        pre_reference_20d = pre_reference_data.tail(20)
        pre_reference_10d = pre_reference_data.tail(10)
        pre_reference_5d = pre_reference_data.tail(5)

        # Metrics dictionary aligned with prompt names
        metrics = {}

        # Volatility metrics
        metrics["pre_reference_volatility_5d"] = pre_reference_5d["High"].sub(pre_reference_5d["Low"]).mean()
        metrics["pre_reference_volatility_10d"] = pre_reference_10d["High"].sub(pre_reference_10d["Low"]).mean()

        # Price change percentages
        metrics["pre_reference_change_5d"] = round(
            ((pre_reference_5d["Close"].iloc[-1] - pre_reference_5d["Close"].iloc[0]) /
             pre_reference_5d["Close"].iloc[0]) * 100, 2)
        metrics["pre_reference_change_10d"] = round(
            ((pre_reference_10d["Close"].iloc[-1] - pre_reference_10d["Close"].iloc[0]) /
             pre_reference_10d["Close"].iloc[0]) * 100, 2)
        metrics["pre_reference_change_20d"] = round(
            ((pre_reference_20d["Close"].iloc[-1] - pre_reference_20d["Close"].iloc[0]) /
             pre_reference_20d["Close"].iloc[0]) * 100, 2)

        # Latest RSI, MACD, and Moving Averages values
        last_row = pre_reference_data.iloc[-1]
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
        raise ValueError(f"Error in pre-reference data calculations: {str(e)}")


def calculate_post_reference_metrics(stock_data, reference_date, reference_day_close):
    """
    Calculate post-reference metrics.
    """
    post_reference_data = stock_data.loc[stock_data.index > reference_date]
    if len(post_reference_data) < 3:
        return {
            "post_reference_change_3d": "N/A",
            "post_reference_3rd_day_close": "N/A",
        }

    post_reference_3d = post_reference_data.head(3)
    post_reference_change_3d = round(
        ((post_reference_3d['Close'].iloc[-1] - reference_day_close) / reference_day_close) * 100, 2
    )
    post_reference_3rd_day_close = post_reference_3d['Close'].iloc[-1]

    return {
        "post_reference_change_3d": post_reference_change_3d,
        "post_reference_3rd_day_close": post_reference_3rd_day_close,
    }

# ==============================================================================
# Part 5: Display functions
# ==============================================================================

def display_data(chat_display, reference_date_str, sector, market_cap, reference_metrics, pre_reference_metrics):
    """
    Display the company and stock data used in the prompt in the chat display.
    """
    chat_display.insert(
        tk.END,
        f"### Company Information ###\n"
        f"- Sector: {sector}\n"
        f"- Market Capitalization (on reference date {reference_date_str}): {market_cap} NOK\n\n"
    )
    chat_display.insert(
        tk.END,
        f"Stock Data:\n"
        f"- Reference Day Price Change: {reference_metrics['price_change']}%\n"
        f"- Reference Day Closing Price: {reference_metrics['closing_price']:.2f} NOK\n" 
        f"- Reference-Day Volume Spike: {reference_metrics['volume_spike']:.2f}%\n"
        f"- Reference-Day Volatility: {reference_metrics['volatility']:.2f} NOK\n"
        f"- Pre-reference 3-Day Moving Average: {pre_reference_metrics['three_day_ma']:.2f} NOK\n"
        f"- Pre-reference 20-Day Moving Average: {pre_reference_metrics['twenty_day_ma']:.2f} NOK\n"
        f"- Pre-reference 5-Day Price Change: {pre_reference_metrics['pre_reference_change_5d']}%\n"
        f"- Pre-reference 5-Day Price Momentum: {pre_reference_metrics['five_day_momentum']:.2f}%\n"
        f"- Pre-reference ATR (3-Day): {pre_reference_metrics['atr_three_day']:.2f} NOK\n"
        f"- Pre-reference 5-Day RSI: {pre_reference_metrics['rsi_5_value']:.2f} ({pre_reference_metrics['rsi_5_status']})\n"
        f"- Pre-reference 20-Day RSI: {pre_reference_metrics['rsi_20_value']:.2f} ({pre_reference_metrics['rsi_20_status']})\n"
        f"- Pre-reference MACD (12-26-9): {pre_reference_metrics['macd_value']:.2f}, MACD Signal: {pre_reference_metrics['macd_signal_value']:.2f} "
        f"({pre_reference_metrics['macd_status']})\n\n"
    )


def display_post_reference_data(chat_display, post_reference_metrics):
    """
    Display the post-reference metrics in the chat display.

    Parameters:
    - chat_display: The tkinter scrolledtext widget for displaying text.
    - post_reference_metrics: Dictionary containing metrics calculated after the reference day.
    """
    chat_display.insert(
        tk.END,
        f"### Post-reference Data ###\n(for validation)\n"
        f"- 3-Day Closing Price: {post_reference_metrics['post_reference_3rd_day_close'] if post_reference_metrics['post_reference_3rd_day_close'] != 'N/A' else 'Not available'} NOK\n"
        f"- 3-Day Post-reference Price Change: {post_reference_metrics['post_reference_change_3d'] if post_reference_metrics['post_reference_change_3d'] != 'N/A' else 'Not enough data'}%\n\n"
    )


# ==============================================================================
# Part 6: Chatbot GUI Class
# ==============================================================================

class ChatbotGUI:
    def __init__(self, master):
        """Initialize the GUI components and attach them to the master window."""
        self.master = master
        master.title("Stock Price Chatbot")
        master.geometry("800x600")
        master.resizable(True, True)

        self.create_widgets()


    def create_widgets(self):
        """Create input fields and buttons for the chatbot interface."""

        # Input field for stock ticker symbol
        ttk.Label(self.master, text="Enter stock symbol (e.g., DNB.OL):").pack(pady=5)
        self.symbol_entry = ttk.Entry(self.master, width=50)
        self.symbol_entry.pack(pady=5)

        # Input field for reference date
        ttk.Label(self.master, text="Enter reference date (YYYY-MM-DD):").pack(pady=5)
        self.reference_date_entry = ttk.Entry(self.master, width=50)
        self.reference_date_entry.pack(pady=5)

        # Button to submit the query
        ttk.Button(self.master, text="Analyze", command=self.analyze).pack(pady=10)

        # Scrollable text box for displaying the result
        self.chat_display = scrolledtext.ScrolledText(self.master, wrap=tk.WORD, width=80, height=20)
        self.chat_display.pack(padx=10, pady=10, expand=True, fill=tk.BOTH)

    # -------------------------------------------------------------------------
    # Helper Functions
    # -------------------------------------------------------------------------
    def validate_inputs(self):
        """
        Validate user inputs for reference date and stock symbol.
        """
        # Validate reference date
        reference_date_str = self.reference_date_entry.get()
        try:
            reference_date = datetime.strptime(reference_date_str, "%Y-%m-%d").replace(tzinfo=ZoneInfo("Europe/Oslo"))
        except ValueError:
            self.chat_display.insert(tk.END, "Invalid date format. Please enter the date as YYYY-MM-DD.\n\n")
            return None, None, None

        # Validate stock symbol
        symbol = self.symbol_entry.get().upper()
        if not symbol:
            self.chat_display.insert(tk.END, "Stock symbol is required. Please enter a valid symbol.\n\n")
            return None, None, None

        return reference_date_str, reference_date, symbol

    # -------------------------------------------------------------------------
    # Main Analyze Function
    # -------------------------------------------------------------------------

    def analyze(self):
        """Handle the user's query and fetch the appropriate data for analysis."""
        # Validate inputs
        reference_date_str, reference_date, symbol = self.validate_inputs()
        if not reference_date_str or not reference_date or not symbol:
            return  # Exit if validation fails

        try:
            # Calculate reference day metrics
            reference_metrics = calculate_reference_day_metrics(symbol, reference_date_str)
            stock_data = reference_metrics.pop("stock_data")
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error calculating reference day metrics: {str(e)}\n\n")
            return

        try:
            # Calculate pre-reference metrics
            pre_reference_metrics = calculate_pre_reference_data(stock_data, reference_date)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error calculating pre-reference metrics: {str(e)}\n\n")
            return

        try:
            # Fetch company information
            sector, market_cap = fetch_company_info(symbol, reference_metrics)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error fetching company information: {str(e)}\n\n")
            return

        try:
            # Calculate post-reference metrics
            post_reference_metrics = calculate_post_reference_metrics(
                stock_data, reference_date, reference_metrics["closing_price"]
            )
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error calculating post-reference metrics: {str(e)}\n\n")
            return

        try:
            # Prepare the GPT prompt
            final_prompt = prepare_final_prompt(
                symbol, reference_metrics, pre_reference_metrics, sector, market_cap
            )
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error preparing the prompt: {str(e)}\n")
            return

        try:
            # Display data used in the prompt
            display_data(
                self.chat_display, reference_date_str, sector, market_cap,
                reference_metrics, pre_reference_metrics
            )
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error displaying data: {str(e)}\n")
            return

        try:
            prediction = gpt_prediction(final_prompt)
            if "Error" in prediction:
                raise ValueError("GPT failed to generate a prediction.")
            self.chat_display.insert(tk.END, f"### Prediction ###\n{prediction}\n\n")
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error fetching prediction: {str(e)}\n")

        try:
            # Display post-reference-day data for validation

            display_post_reference_data(self.chat_display, post_reference_metrics)
        except Exception as e:
            self.chat_display.insert(tk.END, f"Error displaying post-reference data: {str(e)}\n")
            return


# ==============================================================================
# Part 7: Run the GUI
# ==============================================================================
if __name__ == "__main__":
    root = tk.Tk()
    app = ChatbotGUI(master=root)
    root.mainloop()
