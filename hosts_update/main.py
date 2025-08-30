import sys
import json


def print_ip_hosts(ip_hosts):
    for ip, hosts in ip_hosts.items():
        print(f'{ip} {hosts}')


def main(ip_hosts_json, id_comment):
    ip_hosts = json.loads(ip_hosts_json)
    start_comment = f'## START {id_comment} ##'
    end_comment = f'## END {id_comment} ##'
    process = False
    is_processed = False
    for line in sys.stdin.readlines():
        if process:
            if line.strip() == end_comment:
                process = False
                is_processed = True
                print_ip_hosts(ip_hosts)
                print(line, end='')
        elif line.strip() == start_comment:
            process = True
        else:
            print(line, end='')
    assert not process, "Did not find end comment"
    if not is_processed:
        print(f'\n## START {id_comment} ##')
        print_ip_hosts(ip_hosts)
        print(f'## END {id_comment} ##\n')


if __name__ == "__main__":
    main(*sys.argv[1:])
