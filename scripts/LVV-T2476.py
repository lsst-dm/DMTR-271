#!/usr/bin/env python
#
# Test script for LSST Data Management Middleware test
# LVV-T2496:<https://jira.lsstcorp.org/secure/Tests.jspa#/testCase/LVV-T2476>
# LVV-T2496 tests verification element LVV-19749, <https://jira.lsstcorp.org/browse/LVV-19749>
# which verifies middleware requirement DMS-MWBT-REQ-0025-V-01: Format plugability
#
# The lsst environment must be set up to run this test,
# see <https://pipelines.lsst.io/install/setup.html> for more details

import yaml
import os
import shutil
import re

from lsst.daf.butler import CollectionType, DatasetType, Butler, ButlerConfig


def LVVT2496(dir):
    """ Execute the test case LVVT-2496

    Parameters
    ----------
    dir: `str`
        Directory for test artefacts.
    """

    # Create a repo with a default config
    repoDefault = os.path.join(dir, "repo/default")
    assert Butler.makeRepo(repoDefault) is not None
    uriDefault = storeAndRetrieveDataset(repoDefault)
    assert re.search('yaml$', uriDefault.geturl()) is not None

    # Create a repo with a storage class mapped to a different formatter
    config = ButlerConfig(repoDefault).toDict()
    config['datastore']['formatters']['StructuredDataDict'] = 'lsst.daf.butler.formatters.json.JsonFormatter'
    repoModifiedConfig = os.path.join(dir, "repo-modified.yaml")
    with open(repoModifiedConfig, 'w') as outs:
        try:
            yaml.safe_dump(config, outs, default_flow_style=False, explicit_start=True)
        except yaml.YAMLError as e:
            print(e)
    assert os.path.exists(repoModifiedConfig)

    repoModified = os.path.join(dir, "repo/modified")
    assert Butler.makeRepo(repoModified, config=repoModifiedConfig) is not None
    uriModified = storeAndRetrieveDataset(repoModified)
    assert re.search('json$', uriModified.geturl()) is not None


def storeAndRetrieveDataset(repo):
    """ Store and retrieve a dataset in the repository

    Parameters
    ----------
    :param repo: the butler repository
    :return: uri: the URI of the retrieved dataset
    """
    butler = Butler(repo, writeable=True)
    assert butler.registry.registerCollection("c", CollectionType.RUN) is True
    dataset_type = DatasetType("dt", (), "StructuredDataDict", universe=butler.registry.dimensions)
    butler.registry.registerDatasetType(dataset_type)
    butler.put({"key": "value"}, dataset_type, {}, run="c")
    uri = butler.getURI(dataset_type, {}, collections="c")
    assert uri.exists()
    return uri


if __name__ == "__main__":

    # Set up the test directory
    test_case_name = "LVV-T2476"
    base_dir = "/project/leanne/verification"
    test_dir = os.path.join(base_dir, test_case_name)
    if os.path.exists(test_dir):
        shutil.rmtree(test_dir)
    os.makedirs(test_dir)

    # Run the test
    LVVT2496(test_dir)
