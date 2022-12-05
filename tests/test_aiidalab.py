import pytest
import requests
import json
from packaging.version import parse


def test_notebook_service_available(notebook_service):
    response = requests.get(f"{notebook_service}/")
    assert response.status_code == 200


def test_pip_check(aiidalab_exec):
    aiidalab_exec("pip check")


def test_aiidalab_available(aiidalab_exec, nb_user, variant):
    output = aiidalab_exec("aiidalab --version", user=nb_user).decode().strip().lower()
    assert "aiidalab" in output


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).decode().strip()
    assert "conda activate tmp" in output


def test_verdi_status(aiidalab_exec, nb_user):
    output = aiidalab_exec("verdi status", user=nb_user).decode().strip()
    assert "Connected to RabbitMQ" in output
    assert "Daemon is running" in output


@pytest.mark.integration
@pytest.mark.parametrize("package_name", ["aiidalab-widgets-base", "aiidalab-ispg"])
def test_install_apps_from_master(aiidalab_exec, package_name, nb_user):
    output = (
        aiidalab_exec(
            f"aiidalab install --yes {package_name}@git+https://github.com/aiidalab/{package_name}.git",
            user=nb_user,
        )
        .decode()
        .strip()
    )
    assert "ERROR" not in output
    assert "dependency conflict" not in output
    assert f"Installed '{package_name}' version" in output
