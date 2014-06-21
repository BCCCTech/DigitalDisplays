#!/bin/bash
# script to run slideshow in feh

# Wait for windowing system to finish loading -- fix this later
sleep 20

# switch off screensaver
xset s off
xset s noblank
xset -dpms

DELAY=20
CURR_IMG=~/current_slide
SLIDE_DIR=~/slideshow
LOGO_IMG=~/logo.png
DEBUG=0
SCREEN_DIMS=$( xdpyinfo| grep dim | cut -d\  -f 7 )

TWEET="~/twitter_status/tweet.py"

my_host="$(hostname)"
my_ip="$(/sbin/ifconfig  wlan0 | grep "inet addr" | cut -d: -f2 |cut -d\  -f1)"

$TWEET "${my_host}: Online.  IP=${my_IP}"

# returns in input variable 2 the X geometry to scale up image is input variable 1 
# this function is currently unused
function scale_image () 
{
  img_file=$1
  screen_x=$(echo $SCREEN_DIMS | cut -dx -f1)
  screen_y=$(echo $SCREEN_DIMS | cut -dx -f 2)
  img_x=$(identify $img_file | cut -d ' ' -f 3 | cut -dx -f 1)
  img_y=$(identify $img_file | cut -d ' ' -f 3 | cut -dx -f 2)

  scale_x=$(printf "%1.0f" $(echo "($screen_y / $img_y * $img_x)" | bc -l) )
  scale_y=$screen_y
  offx=$(( ($screen_x - $scale_x) / 2 ))
  eval  "$2='${scale_x}x${scale_y}+${offx}+0'"

}

# download a new set of pictures
function update_images () 
{
  # update files in SLIDE_DIR
  rm -f $SLIDE_DIR/*.{jpg,JPG,jpeg,JPEG,png,PNG}
  cd $SLIDE_DIR
  ~/RPiSlideshowImageGetter/SlideshowImageGetter.py

  # check for an update to this file
  if [[ -e $SLIDE_DIR/slideshow.sh ]] ; then
    mv $SLIDE_DIR/slideshow.sh ~/slideshow.sh.new
    
    # if it's different, move it in place and reboot
    if [[ -n $(diff -q ~/slideshow.sh ~/slideshow.sh.new) ]] ; then

      $TWEET "${my_host}: Update detected.  Installing."
      mv ~/slideshow.sh ~/slideshow.sh.old
      mv ~/slideshow.sh.new ~/slideshow.sh
      chmod 755 ~/slideshow.sh
      sudo reboot
    fi
  fi
}

# check for an internet connection
function ping_gw ()
{

  ping -q -w 1 -c 1 $( /sbin/ip r | grep default | cut -d ' ' -f 3) > /dev/null && echo 1 || echo 0

} 

# check to see if the image displaying app is still running
function exit_test ()
{

  [[ -n $(ps -elf | grep feh | grep -v grep) ]] && echo 1 || echo 0

} 

img_geo=""
# start up image slideshow appication
#scale_image $LOGO_IMG img_geo
ln -sf $LOGO_IMG $CURR_IMG
feh -x -Y -F -Z -R 1 $CURR_IMG &
# update files in SLIDE_DIR
[ $(ping_gw) -eq 1 ] &&  update_images

# run until display is killed
while [[ $(exit_test) -eq 1 ]] ; do
  # loop through all the jpgs in SLIDE_DIR and softlink CURR_IMG to each file after DELAY
  IMAGES=$(ls -1 $SLIDE_DIR/*.{jpg,JPG,jpeg,JPEG,png,PNG} )
  for img in $IMAGES ; do
    #scale_image $img img_geo
    ln -sf $img $CURR_IMG
    sleep $DELAY
    [ $(exit_test) -eq 1 ] || break
  done
  #scale_image $LOGO_IMG img_geo
  ln -sf $LOGO_IMG $CURR_IMG
  
  # Update images in slideshow folder
  [ $(exit_test) -eq 1 ] && [ $(ping_gw) -eq 1  ] &&  update_images || break
done

$TWEET "${my_host}: Exit condition detected: exit_test=$(exit_test), ping_gw=$(ping_gw)"

