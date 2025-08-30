import os
import sys
import json
import random


def main(min_, max_, allocation_ids_json, blocked_numbers_json, state_file):
    min_ = int(min_)
    max_ = int(max_)
    allocation_ids = [str(s) for s in json.loads(allocation_ids_json) if s]
    blocked_numbers = [int(n) for n in json.loads(blocked_numbers_json)]
    if os.path.exists(state_file):
        with open(state_file, 'r') as f:
            state = json.load(f)
    else:
        state = {}
    state_changed = False
    for allocation_id in allocation_ids:
        if allocation_id not in state:
            for i in range(100):
                number = random.randint(min_, max_)
                if number not in blocked_numbers and str(number) not in state.values():
                    state[allocation_id] = str(number)
                    state_changed = True
                    break
            assert allocation_id in state, f"Could not find a unique number for allocation ID {allocation_id}"
    if state_changed:
        os.makedirs(os.path.dirname(state_file), exist_ok=True)
        with open(state_file, 'w') as f:
            json.dump(state, f)
    print(json.dumps(state))


if __name__ == '__main__':
    main(*sys.argv[1:])
