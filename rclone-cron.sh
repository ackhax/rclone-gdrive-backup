#!/bin/bash

if pidof -o %PPID -x "rclone-cron.sh"; then
exit 1
fi

rclone copy /MEDIA/audiobooks/ crypt-audiobooks: -v --min-age 15m --log-file=/home/base/rclone-cron-logs/rclone-cron-audiobooks.log
rclone copy /MEDIA/books/ crypt-books: -v --min-age 15m --log-file=/home/base/rclone-cron-logs/rclone-cron-books.log
rclone copy /MEDIA/movies/ crypt-movies: -v --min-age 15m --log-file=/home/base/rclone-cron-logs/rclone-cron-movies.log
rclone copy /MEDIA/music/ crypt-music: -v --min-age 15m --log-file=/home/base/rclone-cron-logs/rclone-cron-music.log
rclone copy /MEDIA/photos/ crypt-photos: -v --min-age 15m --log-file=/home/base/rclone-cron-logs/rclone-cron-photos.log
rclone copy /MEDIA/tv/ crypt-tv: -v --min-age 15m --log-file=/home/base/rclone-cron-logs/rclone-cron-tv.log

exit
