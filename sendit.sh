<<<<<<< Updated upstream
#! /bin/sh 
flutter run -d chrome --web-port=8080
=======
#! /bin/sh


flutter build web
# firebase deploy --only hosting:potato
# firebase deploy --only hosting:explore-the-cell --project=hot-potato-games
# firebase deploy --only hosting:site name --project=hot-potato-games
# this is to be done after adding a flutter app in firebase settings project settings add app
# then adding a hosting site instance in firebase
firebase deploy --only hosting:explore-the-cell --project=hot-potato-games
>>>>>>> Stashed changes
