Fet. El wrapper generat ara fa:

```bash
PROJECT="$(basename "$PWD")"
exec claude --dangerously-skip-permissions --remote-control "${PROJECT}"
```

Exemple d'ús:
```bash
cd /home/salvadorrueda/Developer/fac
claudia   # inicia amb --remote-control "fac"

cd /home/salvadorrueda/Developer/altre-projecte
claudia   # inicia amb --remote-control "altre-projecte"
```