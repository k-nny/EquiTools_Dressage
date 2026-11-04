# Comptes utilisateurs (Firebase) — mise en route

Tant que `lib/compte/firebase_options.dart` contient `A_REMPLACER`, les
comptes sont désactivés : l'appli fonctionne comme avant et aucun bouton de
compte n'apparaît.

## Activer les comptes (plan gratuit « Spark », sans carte bancaire)

1. https://console.firebase.google.com → **Ajouter un projet**
   (désactiver Google Analytics, inutile).
2. **Build → Authentication → Commencer → Adresse e-mail/Mot de passe** :
   activer (laisser « lien par e-mail » désactivé).
3. **Authentication → Paramètres → Domaines autorisés** : ajouter
   `equi-tools-dressage.vercel.app`.
4. **Paramètres du projet (engrenage) → Vos applications → </> Web** :
   enregistrer une appli, copier la « configuration du SDK ».
5. Coller les valeurs (apiKey, appId, messagingSenderId, projectId,
   authDomain, storageBucket) dans `_web` de
   `lib/compte/firebase_options.dart`. La clé web Firebase n'est pas un
   secret : elle peut être dans le dépôt.
6. Pour Android / iOS : ajouter aussi une appli Android et/ou iOS dans la
   console et remplir `_android` / `_ios` de la même façon.
7. `flutter pub get`, puis `flutter run` ou déploiement Vercel.

Quotas gratuits (Spark) : l'authentification par e-mail est gratuite ;
Firestore (étape suivante, sauvegarde des 3 reprises) offre 1 Go et
50 000 lectures / 20 000 écritures par jour, sans mise en pause du projet.

## Sauvegarde des 3 reprises (Firestore)

1. Console Firebase → rechercher **Firestore Database** → **Créer une base de données**.
2. Emplacement : `eur3 (Europe)` (ne peut pas être changé ensuite).
3. Mode : **Production**. Créer.
4. Onglet **Règles** : remplacer tout le contenu par celui du fichier
   `firestore.rules` de ce projet, puis **Publier**.
