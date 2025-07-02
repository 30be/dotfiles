#!/bin/python
import os
from datetime import datetime, timedelta

import yaml
import subprocess
from pathlib import Path

feeds_directory = os.path.join(Path.home(), "books")
log_file = os.path.join(feeds_directory, "log.txt")


def print_to_file(*args, file_path=log_file, sep=" ", end="\n"):
    return
    with open(file_path, "a") as f:
        f.write(sep.join(map(str, args)) + end)


print = print_to_file


def get_chapters(book, file_name):
    with open(os.path.join(feeds_directory, book, file_name), "a+") as f:
        f.seek(0)
        return [
            line.rstrip("\n")
            for line in f.readlines()
            if line.strip() and not line.startswith("#")
        ]


def add_articles(book, amount):
    read_chapters = get_chapters(book, "read_chapters.txt")
    unread_chapters = get_chapters(book, "unread_chapters.txt")

    new_chapters = unread_chapters[:amount]
    read_chapters += new_chapters
    unread_chapters = unread_chapters[amount:]

    with open(os.path.join(feeds_directory, book, "unread_chapters.txt"), "w") as f:
        f.write("\n".join(unread_chapters))
    with open(os.path.join(feeds_directory, book, "read_chapters.txt"), "w") as f:
        f.write("\n".join(read_chapters))

    for chapter in new_chapters:
        subprocess.run(
            f'task add +book +"{book}" project:education.books "{chapter}" reviewed:now',
            shell=True,
            capture_output=True,
        )
    print(f"Added {new_chapters}")


defaults = {
    "last_updated": "2000-01-01",
    "articles_per_day": 1,
    "days_period": 1,
}


def merge_dicts(defaults, config):
    for key, value in defaults.items():
        if key not in config:
            config[key] = value
        elif isinstance(value, dict) and isinstance(config[key], dict):
            merge_dicts(value, config[key])
    return config


def get_config(feed):
    if os.path.exists(os.path.join(feeds_directory, feed, "config.yaml")):
        with open(os.path.join(feeds_directory, feed, "config.yaml"), "r") as file:
            loaded_config = yaml.safe_load(file)
            return merge_dicts(defaults, loaded_config)
    return defaults


def set_config(feed, config):
    with open(os.path.join(feeds_directory, feed, "config.yaml"), "w") as f:
        yaml.dump(config, f)


def update_feed(feed):
    config = get_config(feed)
    last_updated = datetime.fromisoformat(config["last_updated"])
    last_updated_day = last_updated.replace(hour=0, minute=0, second=0, microsecond=0)
    update_timepoint = last_updated_day + (0.99 * timedelta(days=config["days_period"]))
    if datetime.now() >= update_timepoint:
        call = subprocess.run(f'task +"{feed}"', shell=True, capture_output=True)
        if call.returncode:  # no such task (yet)
            add_articles(feed, config["articles_per_day"])
            config["last_updated"] = datetime.now().isoformat()
            set_config(feed, config)
            print("Updating", feed)
        else:
            print(f"Already have {feed} in chapters!")
    else:
        print(f"Last updated {feed}: {last_updated}")


def main():
    if not os.path.exists(os.path.join(feeds_directory, "generate_flag")):
        print("Not generating feeds because generate_flag file does not exist")
        exit(0)

    for feed in os.listdir(feeds_directory):
        if os.path.isdir(os.path.join(feeds_directory, feed)):
            update_feed(feed)


if __name__ == "__main__":
    main()
