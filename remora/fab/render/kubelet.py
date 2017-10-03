#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import os

from fabric.api import env
from fabric.api import execute
from fabric.api import runs_once
from fabric.api import task
from fabric.operations import require

from remora.fab import constants
from remora.fab import helpers


def generate_local_env():
    return helpers.generate_local_env() + master_env_list() + cert_env_list()


def render(script_name, *options):
    helpers.run_script(
        script_name,
        *options,
        local_env=generate_local_env()
    )


def cert_env_list():
    kubelet_asset_dir = constants.kubelet_asset_dir(env.host)
    return [
        'export CLIENT_KEY="{}"'.format(
            os.path.join(kubelet_asset_dir, 'kubelet.key')
        ),
        'export CLIENT_CERT_REQ="{}"'.format(
            os.path.join(kubelet_asset_dir, 'kubelet.csr')
        ),
        'export CLIENT_CERT="{}"'.format(
            os.path.join(kubelet_asset_dir, 'kubelet.crt')
        ),
        'export LOCAL_KUBELET_ASSETS_DIR="{}"'.format(kubelet_asset_dir),
    ]


def master_env_list():
    if env.host in env.roledefs.get('master', []):
        return ['export KUBE_IS_MASTER="1"']
    return ['export KUBE_IS_MASTER="0"']


@task(default=True)
@runs_once
def all():
    execute(kubelet)


@task
def kubelet():
    require('stage')
    render(
        'gen-cert-kubelet.sh',
        env.host,
        'kubelet',
        '"/O=system:nodes/CN=system:node:{}"'.format(env.host)
    )
    render(
        'kubelet/render.sh',
        env.host
    )