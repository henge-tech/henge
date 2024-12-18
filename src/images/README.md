# Henge Images

## Prepare

```
$ ruby --version
ruby 3.1.3p...

$ brew install imagemagick
$ bundle install
```

## Edit

Generate source. Copy & Paste to the `images.txt`.

```
ruby bin/image_edit.rb 10
```

Generate URLs.

```
ruby bin/image_edit.rb 10 1 | less
```

And edit `images.txt`.

## Download

```
./bin/image_downloader.sh
```

## Generate thumbnails

```
ruby ./bin/circle_image_generator.rb
```

## Upload

```
aws-vault exec xxxx
./bin/s3sync.sh
```
