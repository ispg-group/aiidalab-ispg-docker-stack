import pytest
import requests
import json
import urllib3
from packaging.version import parse


def test_notebook_service_available(notebook_service):
    # Disable warning coming from self-signed SSL certificate
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    # Do not verify SSL certificate
    response = requests.get(f"{notebook_service}/", verify=False)
    assert response.status_code == 200


def test_pip_check(aiidalab_exec):
    aiidalab_exec("pip check")


def test_aiidalab_available(aiidalab_exec, nb_user):
    output = aiidalab_exec("aiidalab --version", user=nb_user).strip().lower()
    assert "aiidalab" in output


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).strip()
    assert "conda activate tmp" in output


def test_verdi_status(aiidalab_exec, nb_user):
    output = aiidalab_exec("verdi status", user=nb_user).strip()
    for status in ("version", "config", "profile", "storage", "broker", "daemon"):
        assert f"✔ {status}" in output
    assert "/home/jovyan/.aiida" in output
    assert "Daemon is running" in output
    assert "Unable to connect to broker" not in output


@pytest.mark.parametrize(
    "app",
    [
        "aiidalab/aiidalab-widgets-base",
        "ispg-group/aiidalab-ispg",
    ],
)
def test_install_apps_from_master(aiidalab_exec, app, nb_user):
    owner, appname = app.split("/")
    output = aiidalab_exec(
        f"aiidalab install --yes {appname}@git+https://github.com/{owner}/{appname}",
        user=nb_user,
    ).strip()
    assert "ERROR" not in output
    assert "dependency conflict" not in output
    assert f"Installed '{appname}' version" in output
