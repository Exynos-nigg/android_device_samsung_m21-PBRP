# Buildbot script for CircleCI
# coded by bruh™ aka Exynos-nigg

MANIFEST_LINK=git://github.com/PitchBlackRecoveryProject/manifest_pb.git
BRANCH=android-10.0
DEVICE_CODENAME=m21
GITHUB_USER=Exynos-nigg
GITHUB_EMAIL=vsht700@gmail.com
WORK_DIR=$(pwd)/PBRP-${DEVICE_CODENAME}
JOBS=$(nproc)
SPACE=$(df -h)
RAM=$(free mem -h)

# Check CI specs!
echo "Checking specs!"
echo "CPU cores = ${JOBS}"
echo "Space available = ${SPACE}"
echo "RAM available = ${RAM}"
sleep 25 

# Set up git!
echo ""
echo "Setting up git!"
git config --global user.name ${GITHUB_USER}
git config --global user.email ${GITHUB_EMAIL}
git config --global color.ui true

# Install dependencies!
echo ""
echo "Installing dependencies!"
apt-get -y update && apt-get -y upgrade && apt-get -y install bc bison build-essential curl flex g++-multilib gcc gcc-multilib clang gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev unzip openjdk-8-jdk python ccache libtinfo5 repo libstdc++6 libssl-dev rsync
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# randomize and fix sync thread number, according to available cpu thread count
SYNC_THREAD=$(grep -c ^processor /proc/cpuinfo)          # Default CPU Thread Count
if [[ $(echo ${JOBS}) -le 2 ]]; then SYNC_THREAD=$(shuf -i 5-7 -n 1)        # If CPU Thread >= 2, Sync Thread 5~7
elif [[ $(echo ${JOBS}) -le 8 ]]; then SYNC_THREAD=$(shuf -i 12-16 -n 1)    # If CPU Thread >= 8, Sync Thread 12~16
elif [[ $(echo ${JOBS}) -le 36 ]]; then SYNC_THREAD=$(shuf -i 30-36 -n 1)   # If CPU Thread >= 36, Sync Thread 30~36
fi

# make directories
echo ""
echo "Setting work directories!"
mkdir ${WORK_DIR} && cd ${WORK_DIR}

# set up rom repo
echo ""
echo "Syncing rom repo!"
repo init -u ${MANIFEST_LINK} -b ${BRANCH} --depth=1
repo sync -j${SYNC_THREAD}

# clone device sources
echo ""
echo "Cloning device sources!"

# Device tree
git clone -b android-10.0 https://github.com/Exynos-nigg/android_device_samsung_m21-PBRP device/samsung/m21

# Kernel source 
# placeholder

# extra dependencie for building dtbo
git clone -b lineage-17.1 https://github.com/LineageOS/android_hardware_samsung.git hardware/samsung

# Start building!
echo ""
echo "Starting build!"
export LC_ALL=C
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh && lunch omni_${DEVICE_CODENAME}-eng && mka recoveryimage -j${JOBS}

# copy final product to another folder
echo ""
echo "Copying final product to another dir!"
mkdir ~/output
cp ${WORK_DIR}/out/target/product/*/*.zip ~/output/
cp ${WORK_DIR}/out/target/product/*/recovery.img ~/output/

echo ""
echo "Done baking!"
echo "Build will be uploaded in the artifacts section in CircleCI! =) "
echo ""