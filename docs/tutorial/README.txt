Como compilar arquivos .tex:
 $ pdflatex <arquivo>.tex
 $ pdflatex <arquivo>.tex

Na primeira execução, o pdf gerado contém "??" no lugar dos números de
referência à seções/códigos/figuras. Por isso a repetição do comando. Na
primeira, foi gerado um índice e na segunda, o arquivo intermediário de índice
já existe e já será usado. 

Se houverem referências bibliográficas, acontece algo similar, por isso faça:
 $ pdflatex <arquivo>.tex
 $ bibtex <arquivo>.tex
 $ pdflatex <arquivo>.tex
 $ pdflatex <arquivo>.tex
