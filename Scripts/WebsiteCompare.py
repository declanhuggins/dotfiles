import os
import re
import subprocess
import threading
import time
import pyautogui
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ---------------------------
# Helper Functions for Filenames
# ---------------------------
def slugify(text):
    """
    Converts a string to a safe slug: lowercase, spaces and commas replaced by underscores,
    and non-alphanumeric characters removed.
    """
    text = text.lower()
    text = re.sub(r'[\s,]+', '_', text)
    text = re.sub(r'[^a-z0-9_-]', '', text)
    return text

def get_output_filename_for_scenario(cache_label, theme, pair_slug):
    """
    Generate a filename slug based on scenario parameters.
    For example: "scenario_cache_on_theme_light_testing_vs_dhugs.mp4"
    If the file exists, appends a counter.
    """
    base_slug = f"scenario_{slugify(cache_label)}_{slugify(theme)}_{pair_slug}"
    filename = f"{base_slug}.mp4"
    if not os.path.exists(filename):
        return filename
    i = 1
    while True:
        new_filename = f"{base_slug}_{i}.mp4"
        if not os.path.exists(new_filename):
            return new_filename
        i += 1

def get_combined_filename(pair_slug):
    """
    Generate a combined output filename for a website pair with a timestamp.
    For example: "combined_testing_vs_dhugs_20230415_153045.mp4"
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"combined_{pair_slug}_{timestamp}.mp4"
    return filename

# ---------------------------
# FFmpeg Recording Function
# ---------------------------
def start_ffmpeg_recording(filename):
    """
    Start FFmpeg recording using avfoundation on macOS at 60 fps.
    The recorded resolution is 1800x1169. We then crop off the top 38 pixels (i.e. 
    keep a region of 1800x1102 starting at y=38) and pad the bottom with 38 pixels so 
    that each output video is exactly 1800x1169.
    """
    print(f"[FFmpeg] Recording will be saved to: {filename}")
    ffmpeg_cmd = [
        "ffmpeg",
        "-f", "avfoundation",
        "-framerate", "60",
        "-i", "3:none",  # Device index 3: "Capture screen 0"
        "-vf", "scale=1800:1169, crop=1800:1130:0:39",
        filename
    ]
    return subprocess.Popen(ffmpeg_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# ---------------------------
# OS-Level Window Management Functions
# ---------------------------
def bring_firefox_to_front():
    """Use AppleScript to bring Firefox to the front."""
    subprocess.call(["osascript", "-e", 'tell application "Firefox" to activate'])

def minimize_terminal():
    """Use AppleScript to minimize the Terminal window."""
    subprocess.call(["osascript", "-e", 'tell application "Terminal" to set miniaturized of front window to true'])

# ---------------------------
# Firefox Profile Creation
# ---------------------------
def create_firefox_profile(disable_cache, theme):
    """
    Create a Firefox profile that disables cache if requested and sets the UI theme
    (dark/light) using the "ui.systemUsesDarkTheme" preference.
    """
    profile = FirefoxProfile()
    if disable_cache:
        profile.set_preference("browser.cache.disk.enable", False)
        profile.set_preference("browser.cache.memory.enable", False)
        profile.set_preference("browser.cache.offline.enable", False)
        profile.set_preference("network.http.use-cache", False)
    if theme == "dark":
        profile.set_preference("ui.systemUsesDarkTheme", 1)
    else:
        profile.set_preference("ui.systemUsesDarkTheme", 0)
    profile.update_preferences()
    return profile

# ---------------------------
# Browser Worker Function
# ---------------------------
def browse_site(url, x, y, width, height, disable_cache, theme, setup_barrier, recording_started, click_barrier):
    """
    Opens a Firefox window (with the given cache and theme settings) at the specified position/size.
    Waits for synchronization, then loads the URL and performs a series of synchronized interactions:
    
    1. Clicks the ABOUT button.
    2. Clicks the home button (link text "Declan Huggins").
    3. Clicks the PORTFOLIO button.
    4. Clicks the home button.
    5. Clicks the MINECRAFT button.
    6. Clicks the home button.
    7. Clicks the Dec 20 post, scrolls down, and then clicks on the first non-SVG image.
    
    For sites on dhugs.com, before clicking on ABOUT, PORTFOLIO, or MINECRAFT,
    the script will click on the "menu-toggle" element.
    """
    profile = create_firefox_profile(disable_cache, theme)
    options = webdriver.FirefoxOptions()
    options.profile = profile
    driver = webdriver.Firefox(options=options)
    driver.set_window_position(x, y)
    driver.set_window_size(width, height)
    driver.execute_script("window.focus();")
    
    setup_barrier.wait()
    bring_firefox_to_front()
    recording_started.wait()
    
    driver.get(url)
    try:
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )
    except Exception as e:
        print(f"Error loading {url}: {e}")
    
    # Check if the current site is dhugs.com
    is_dhugs = "dhugs.com" in url.lower()

    # Helper function for synchronized clicks
    def synchronized_click(by, value, description, post_sleep=2):
        try:
            element = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((by, value))
            )
            click_barrier.wait()  # Wait for the other thread
            
            # For dhugs.com, click menu-toggle before clicking certain buttons
            if is_dhugs and description in {"ABOUT button", "PORTFOLIO button", "MINECRAFT button"}:
                try:
                    menu_toggle = WebDriverWait(driver, 10).until(
                        EC.element_to_be_clickable((By.ID, "menu-toggle"))
                    )
                    menu_toggle.click()
                    time.sleep(1)
                except Exception as e:
                    print("Error clicking menu-toggle:", e)
            element.click()
            time.sleep(post_sleep)
        except Exception as e:
            print(f"Error clicking {description}:", e)
    
    time.sleep(1)

    # 1. Click the ABOUT button
    synchronized_click(By.LINK_TEXT, "ABOUT", "ABOUT button")
    
    # 2. Click the home button (Declan Huggins)
    synchronized_click(By.LINK_TEXT, "Declan Huggins", "Home button after ABOUT")
    
    # 3. Click the PORTFOLIO button
    synchronized_click(By.LINK_TEXT, "PORTFOLIO", "PORTFOLIO button")
    
    # 4. Click the home button again
    synchronized_click(By.LINK_TEXT, "Declan Huggins", "Home button after PORTFOLIO")
    
    # 5. Click the MINECRAFT button
    synchronized_click(By.LINK_TEXT, "MINECRAFT", "MINECRAFT button")
    
    # 6. Click the home button again
    synchronized_click(By.LINK_TEXT, "Declan Huggins", "Home button after MINECRAFT")
    
    # 7. Click the Dec 20 post, scroll, and then click on the first non-SVG image
    synchronized_click(By.PARTIAL_LINK_TEXT, "Dec 20", "Dec 20 post")
    try:
        driver.execute_script("window.scrollBy(0, 300);")
        time.sleep(2)
        click_barrier.wait()  # Synchronize before image selection

        images = driver.find_elements(By.TAG_NAME, "img")
        target_found = False
        for img in images:
            src = img.get_attribute("src")
            if src and not src.lower().endswith(".svg"):
                img.click()
                target_found = True
                time.sleep(2)
                break
        if not target_found:
            print("No non-SVG image found.")
    except Exception as e:
        print("Error interacting with non-SVG image:", e)

    driver.execute_script("window.focus();")
    driver.execute_script(
        "document.documentElement.style.cursor = 'none';"
        "document.body.style.cursor = 'none';"
    )
    time.sleep(10)
    driver.quit()

# ---------------------------
# Combine Videos Function
# ---------------------------
def combine_videos(video_tonl, video_toff, video_donl, video_doff, output):
    """
    Combine four video files into one composite video arranged in a 2x2 grid.
    Assumes each input video is 1800x1130.
    The final composite video will be 3600x2260.
    """
    filter_complex = (
        "[0:v]setpts=PTS-STARTPTS[v0];"
        "[1:v]setpts=PTS-STARTPTS[v1];"
        "[2:v]setpts=PTS-STARTPTS[v2];"
        "[3:v]setpts=PTS-STARTPTS[v3];"
        "[v0][v1]hstack=inputs=2[top];"
        "[v2][v3]hstack=inputs=2[bottom];"
        "[top][bottom]vstack=inputs=2[out]"
    )
    cmd = [
        "ffmpeg",
        "-i", video_tonl,
        "-i", video_toff,
        "-i", video_donl,
        "-i", video_doff,
        "-filter_complex", filter_complex,
        "-map", "[out]",
        "-c:v", "libx264",
        "-crf", "23",
        "-preset", "veryfast",
        output
    ]
    print("Combining videos with FFmpeg...")
    subprocess.run(cmd, check=True)
    print(f"Combined video saved as {output}")

# ---------------------------
# Test Set Runner Function
# ---------------------------
def run_test_set(disable_cache, theme, left_site, right_site, pair_slug, group_name):
    """
    Runs one scenario between two websites with the given cache and theme settings.
    Returns the output filename.
    """
    print(f"\n=== Running Scenario: {group_name} ===")
    print(f"Cache Disabled: {disable_cache}, Theme: {theme}")
    print(f"Left: {left_site}, Right: {right_site}")
    
    width = 900
    height = 1169  # Recorded resolution before cropping/padding.
    url_left = f"https://{left_site}"
    url_right = f"https://{right_site}"
    
    setup_barrier = threading.Barrier(3)
    recording_started = threading.Event()
    click_barrier = threading.Barrier(2)  # Synchronize clicks between the two browsers.
    
    left_thread = threading.Thread(
        target=browse_site,
        args=(url_left, 0, 0, width, height, disable_cache, theme, setup_barrier, recording_started, click_barrier)
    )
    right_thread = threading.Thread(
        target=browse_site,
        args=(url_right, 900, 0, width, height, disable_cache, theme, setup_barrier, recording_started, click_barrier)
    )
    
    left_thread.start()
    right_thread.start()
    setup_barrier.wait()
    
    bring_firefox_to_front()
    minimize_terminal()
    pyautogui.moveTo(0, height)
    
    cache_label = "cache_off" if disable_cache else "cache_on"
    output_filename = get_output_filename_for_scenario(cache_label, theme, pair_slug)
    
    ffmpeg_process = start_ffmpeg_recording(output_filename)
    time.sleep(2)
    recording_started.set()
    
    left_thread.join()
    right_thread.join()
    
    ffmpeg_process.terminate()
    stdout, stderr = ffmpeg_process.communicate()
    print("[FFmpeg] stdout:", stdout.decode())
    print("[FFmpeg] stderr:", stderr.decode())
    print(f"=== Scenario '{group_name}' completed ===\n")
    time.sleep(3)
    return output_filename

# ---------------------------
# Main Loop: Iterate Over Round Robin Pairs & Scenarios
# ---------------------------
if __name__ == "__main__":
    # Define website pairs.
    website_pairs = [
        ("testing.dhugs.com", "dev.dhugs.com"),
        ("testing.dhugs.com", "dhugs.com"),
        ("dev.dhugs.com", "dhugs.com")
    ]
    
    # Define scenario parameters in fixed order:
    # Order: Top-left: Cache On + Light; Top-right: Cache Off + Light;
    # Bottom-left: Cache On + Dark; Bottom-right: Cache Off + Dark.
    conditions = [("Cache On", "light"), ("Cache Off", "light"),
                  ("Cache On", "dark"), ("Cache Off", "dark")]
    
    for left_site, right_site in website_pairs:
        pair_slug = f"{slugify(left_site)}_vs_{slugify(right_site)}"
        outputs = {}
        scenario_number = 1
        total_scenarios = len(conditions)
        for cache_label, theme in conditions:
            disable_cache = False if cache_label == "Cache On" else True
            scenario_name = (f"Scenario {scenario_number}/{total_scenarios} - "
                             f"{cache_label}, {theme.capitalize()} Mode, Pair: {left_site} vs {right_site}")
            output_file = run_test_set(disable_cache, theme, left_site, right_site, pair_slug, scenario_name)
            outputs[(cache_label, theme)] = output_file
            scenario_number += 1
        
        combined_filename = get_combined_filename(pair_slug)
        try:
            combine_videos(
                outputs[("Cache On", "light")],
                outputs[("Cache Off", "light")],
                outputs[("Cache On", "dark")],
                outputs[("Cache Off", "dark")],
                combined_filename
            )
            for fname in outputs.values():
                os.remove(fname)
                print(f"Removed temporary file: {fname}")
        except Exception as e:
            print(f"Error combining videos for pair {pair_slug}: {e}")
    
    print("All scenarios completed and combined videos created.")
