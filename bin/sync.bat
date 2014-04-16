set MEDIA_DIR=D:/dropbox/media.drafts.cc/
aws s3 sync s3://media.drafts.cc %MEDIA_DIR% --exclude "*" --include "*.jpg" --include "*.png"
aws s3 sync %MEDIA_DIR% s3://media.drafts.cc --exclude "*" --include "*.jpg" --content-type "image/jpeg"
aws s3 sync %MEDIA_DIR% s3://media.drafts.cc --exclude "*" --include "*.png" --content-type "image/png"
