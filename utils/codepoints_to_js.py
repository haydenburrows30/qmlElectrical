with open('text.txt','r') as f:
    string = "'"
    sentences = []
    for line in f:
        s = line.replace(" ", ":'u").replace(":'u",": '\\u")
        s1 = s[:-1]
        s2 = s1 + "'"
        sentences.append(s2)

with open('filename.txt','w') as f:
    for row in sentences:
        f.write(str(row) + ',' +  '\n')