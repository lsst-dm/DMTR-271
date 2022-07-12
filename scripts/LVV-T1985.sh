#!/bin/bash
# Script to execute LVVT-1985
# Execute on the NCSA machines
# -------------------------------

# Test directory
TEST_DIR="/project/leanne/verification/LVV-T1985"
mkdir -p $TEST_DIR

# Datasets used for test
SRC_DATASET_HSC="/project/shared/hsc/COSMOS/2014-03-27/"
SRC_DATASET_COMCOM="/project/shared/comCam/_parent/raw/2022-05-05/2022050500005/"
SRC_DATASET_LATISS="/project/shared/auxTel/_parent/raw/2022-04-06"

# Instruments
INSTRUMENT_HSC="HSC"
INSTRUMENT_HSC_CLASS="lsst.obs.subaru.HyperSuprimeCam"
INSTRUMENT_LATISS="LATISS"
INSTRUMENT_LATISS_CLASS="lsst.obs.lsst.Latiss"
INSTRUMENT_COMCAM="LSSTComCam"
INSTRUMENT_COMCAM_CLASS="lsst.obs.lsst.LsstComCam"

# Test dataset
TEST_DATASET_DIR=$TEST_DIR/data
mkdir -p $TEST_DATASET_DIR
cp -R $SRC_DATASET_LATISS $TEST_DATASET_DIR
cp -R $SRC_DATASET_COMCOM $TEST_DATASET_DIR
cp -R $SRC_DATASET_HSC $TEST_DATASET_DIR

TEST_DATASET_LATISS=$TEST_DIR/data/`basename $SRC_DATASET_LATISS`
TEST_DATASET_COMCAM=$TEST_DIR/data/`basename $SRC_DATASET_COMCOM`
TEST_DATASET_HSC=$TEST_DIR/data/`basename $SRC_DATASET_HSC`

# Setup the lsst environment
source /software/lsstsw/stack/loadLSST.bash
setup lsst_distrib

# Repo
REPO=${TEST_DIR}/"repo"
mkdir -p -m 755  $REPO

## Create butler repo
butler create $REPO

## Check config for new butler
REPO_CONFIG_FILE=$TEST_DIR/"repo.config"
butler config-dump $REPO --file $REPO_CONFIG_FILE

# Register the instrument - can be referred to by the short name after registering
butler register-instrument $REPO $INSTRUMENT_LATISS_CLASS
butler register-instrument $REPO $INSTRUMENT_COMCAM_CLASS
butler register-instrument $REPO $INSTRUMENT_HSC_CLASS

# Write the curated calibrations
butler write-curated-calibrations $REPO $INSTRUMENT_LATISS_CLASS
butler write-curated-calibrations $REPO $INSTRUMENT_COMCAM_CLASS
butler write-curated-calibrations $REPO $INSTRUMENT_HSC_CLASS

# Check the outputs
butler query-dimension-records $REPO instrument
butler query-collections $REPO --chains=tree

# Ingest all raws
butler ingest-raws $REPO $TEST_DATASET_LATISS --transfer link
butler ingest-raws $REPO $TEST_DATASET_COMCAM --transfer link
butler ingest-raws $REPO $TEST_DATASET_HSC --transfer link

# Take a look at the repository
butler query-collections $REPO --chains=tree
butler query-dimension-records $REPO exposure --where "instrument='HSC' AND exposure.observation_type='science'"
butler query-dimension-records $REPO exposure --where "instrument='LATISS' AND exposure.observation_type='dark'"
butler query-dimension-records $REPO exposure --where "instrument='COMCAM' AND exposure.observation_type='bias'"
butler query-dimension-records $REPO exposure --where "instrument='LATISS' AND exposure.observation_type='flat'"

# Remove all test artefacts
# rm -rf  $TEST_DIR