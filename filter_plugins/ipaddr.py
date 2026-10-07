"""
filter_plugins/ipaddr.py — re-export фильтра ``ipaddr`` из ansible.utils.

В ansible-core 2.19+ объявление ``collections: [ansible.utils]`` в
playbook/role НЕ делает короткое имя ``ipaddr`` доступным внутри
шаблонов (Jinja2). Объявление ``filter_plugins = filter_plugins`` в
ansible.cfg подразумевает наличие локальных плагинов-обёрток, что и
делает этот файл.
"""
from ansible_collections.ansible.utils.plugins.filter.ipaddr import (  # noqa: F401
    FilterModule,
)
