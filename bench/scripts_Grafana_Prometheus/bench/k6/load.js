/**
 * Script de charge k6 pour les scénarios B1, B2 et B5 (§9 du sujet).
 *
 * Variables d'environnement (option -e de k6) :
 *   SCENARIO    : b1 | b2 | b5            (défaut : b1)
 *   URL         : URL complète de l'endpoint d'inférence
 *   HOST_HEADER : en-tête Host, utile derrière un ingress KServe/Knative
 *
 * Exemple :
 *   k6 run -e SCENARIO=b1 -e URL=http://192.168.122.50:30080/v1/models/housing-sklearn:predict load.js
 */
import http from 'k6/http';
import { check } from 'k6';

const URL = __ENV.URL;
if (!URL) {
  throw new Error('Variable URL manquante (utiliser -e URL=...)');
}

// Requête d'exemple de l'Annexe B : 1 instance, 8 variables
const PAYLOAD = JSON.stringify({
  instances: [[8.3252, 41.0, 6.98, 1.02, 322.0, 2.55, 37.88, -122.23]],
});

const HEADERS = { 'Content-Type': 'application/json' };
if (__ENV.HOST_HEADER) {
  HEADERS['Host'] = __ENV.HOST_HEADER;
}

// Paliers de B2 : nombre de clients simultanés, 2 minutes chacun
const B2_PALIERS = [1, 5, 10, 25, 50];

// Définition des scénarios, sélectionnés via la variable SCENARIO
const SCENARIOS = {
  // B1 : référence, 1 client, 500 requêtes séquentielles
  b1: {
    b1: { executor: 'shared-iterations', vus: 1, iterations: 500, maxDuration: '10m' },
  },

  // B2 : montée en charge, paliers successifs de 2 min (startTime les enchaîne)
  b2: Object.fromEntries(
    B2_PALIERS.map((vus, i) => [
      `palier_${vus}`,
      { executor: 'constant-vus', vus, duration: '2m', startTime: `${i * 2}m` },
    ]),
  ),

  // B5 : créneau 0 -> 50 -> 0 clients (montée, plateau, descente, repos)
  b5: {
    b5: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '5m', target: 50 },
        { duration: '1m', target: 0 },
        { duration: '5m', target: 0 },  // laisse le temps au scale-down
      ],
    },
  },
};

export const options = {
  scenarios: SCENARIOS[__ENV.SCENARIO || 'b1'],
  // Statistiques demandées par le protocole : médiane, p95, p99
  summaryTrendStats: ['min', 'med', 'p(95)', 'p(99)', 'max'],
};

// Fonction exécutée en boucle par chaque client virtuel
export default function () {
  const res = http.post(URL, PAYLOAD, { headers: HEADERS });
  check(res, {
    'statut 200': (r) => r.status === 200,
    'prédiction présente': (r) => r.json('predictions') !== undefined,
  });
}
