import requests
import json

import os
from dotenv import load_dotenv

load_dotenv(dotenv_path=".env")

API_KEY = os.getenv("API_KEY")

HANDLE = "MrBeast"
maxresults = 50 

def get_playlistId():

    try:

        url = f"https://youtube.googleapis.com/youtube/v3/channels?part=contentDetails&forHandle={HANDLE}&key={API_KEY}"

        response = requests.get(url)

        response.raise_for_status()

        data = response.json()

        channel_items = data['items'][0]

        channel_playlistId = channel_items["contentDetails"]["relatedPlaylists"]["uploads"]

        return channel_playlistId

    except requests.exceptions.RequestException as e:
        raise e

def get_videos_ids(playlistId):

    video_ids = []

    pageToken = None

    base_url = f"https://youtube.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId={playlistId}&maxResults={maxresults}&key={API_KEY}"

    try:

        while True:

            url = base_url

            if pageToken:
                url += f"&pageToken={pageToken}"

            response = requests.get(url)

            response.raise_for_status()

            data = response.json()

            #print (json.dumps(data, indent=4))

            video_items = data['items']

            for item in video_items:
                video_id = item["contentDetails"]["videoId"]
                video_ids.append(video_id)

            pageToken = data.get("nextPageToken")

            if not pageToken:
                break

        return video_ids

    except requests.exceptions.RequestException as e:
        raise e


if __name__ == "__main__":
    PlaylistId = get_playlistId()
    
    (get_videos_ids(PlaylistId))