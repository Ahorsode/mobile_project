import json
import re

def parse():
    with open('lesson_dump.txt', 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    tiers = []
    current_tier = None
    current_lesson = None
    current_section = None
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        if line.startswith('Tier '):
            current_tier = {'title': line, 'lessons': []}
            tiers.append(current_tier)
            continue
            
        if line.startswith('Lesson '):
            m = re.match(r'Lesson ([\d\.]+): (.*)', line)
            if m:
                current_lesson = {
                    'id': m.group(1),
                    'title': m.group(2),
                    'theory': '',
                    'logic': '',
                    'codeDiscovery': '',
                    'quest': '',
                    'quiz': []
                }
                if current_tier:
                    current_tier['lessons'].append(current_lesson)
            continue
            
        if not current_lesson:
            continue
            
        if line.startswith('The Theory:'):
            current_lesson['theory'] = line[11:].strip()
            current_section = 'theory'
        elif line.startswith('The Logic:'):
            current_lesson['logic'] = line[10:].strip()
            current_section = 'logic'
        elif line.startswith('Code Discovery:'):
            current_section = 'code'
        elif line.startswith('The Quest:'):
            current_lesson['quest'] = line[10:].strip()
            current_section = 'quest'
        elif line.startswith('Checkpoint Quiz:'):
            current_section = 'quiz'
        elif line.startswith('+'):
            if current_section == 'quiz' and current_lesson['quiz']:
                try:
                    current_lesson['quiz'][-1]['correctIndex'] = int(line[1:]) - 1
                except:
                    pass
        else:
            if current_section == 'theory':
                current_lesson['theory'] += ' ' + line
            elif current_section == 'logic':
                current_lesson['logic'] += ' ' + line
            elif current_section == 'code' and line != 'Python':
                current_lesson['codeDiscovery'] += line + '\n'
            elif current_section == 'quest':
                current_lesson['quest'] += ' ' + line
            elif current_section == 'quiz':
                if line.startswith('A)'):
                    current_lesson['quiz'][-1]['options'].append(line[2:].strip())
                elif line.startswith('B)'):
                    current_lesson['quiz'][-1]['options'].append(line[2:].strip())
                else:
                    current_lesson['quiz'].append({'question': line, 'options': []})
    
    return tiers

if __name__ == '__main__':
    data = parse()
    with open('assets/lessons.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
