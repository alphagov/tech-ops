python3 geturls.py | parallel -j 8 wget  --recursive   --adjust-extension       --directory-prefix static/       --continue       --wait=0       --no-parent
wget  --page-requisites   --adjust-extension       --directory-prefix static/       --continue       --wait=0       --no-parent https://performance-platform-spotlight-live.cloudapps.digital/performance/
python3 sanitise.py
# Now cd into static and cf v3-zdt-push performance-platform-spotlight-static
