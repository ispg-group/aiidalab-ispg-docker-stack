import json
from pathlib import Path

import pytest
import requests
import urllib3

from requests.exceptions import ConnectionError  # noqa: A004

def is_responsive(url):
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    try:
        response = requests.get(url, verify=False)
        if response.status_code == 200:
            return True
        else:
            print("{response.status_code}: {response}")
            return False
    except ConnectionError:
        return False


@pytest.fixture(scope="session")
def notebook_service(docker_ip, docker_services):
    """Ensure that HTTP service is up and responsive."""
    port = docker_services.port_for("aiidalab", 8888)
    url = f"http://{docker_ip}:{port}"
    docker_services.wait_until_responsive(
        timeout=60.0, pause=1.0, check=lambda: is_responsive(url)
    )
    return url


@pytest.fixture(scope="session")
def docker_compose(docker_services):
    return docker_services._docker_compose


@pytest.fixture
def aiidalab_exec(docker_compose):
    def execute(command, user=None, **kwargs):
        if user:
            command = f"exec -T --user={user} aiidalab {command}"
        else:
            command = f"exec -T aiidalab {command}"
        out = docker_compose.execute(command, **kwargs)
        return out.decode()

    return execute


@pytest.fixture
def nb_user(aiidalab_exec):
    return aiidalab_exec("bash -c 'echo \"${NB_USER}\"'").strip()
