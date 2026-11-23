'use strict';

const $ = (id) => document.getElementById(id);
const editor = $('editor');
const numeros = $('numeros');
const estado = $('estado');
const resumen = $('resumen');
const soluciones = $('soluciones');
const errores = $('errores');
const explicacion = $('explicacion');

function actualizarLineas() {
  const total = editor.value.split('\n').length;
  numeros.textContent = Array.from({length: total}, (_, i) => i + 1).join('\n');
  $('estado-lineas').textContent = `Línea ${total}`;
}

function insertar(texto) {
  const inicio = editor.selectionStart;
  const fin = editor.selectionEnd;
  editor.setRangeText(texto, inicio, fin, 'end');
  actualizarLineas();
  editor.focus();
}

function irALinea(linea) {
  const n = Math.max(1, Number(linea) || 1);
  const partes = editor.value.split('\n');
  let indice = 0;
  for (let i = 0; i < n - 1 && i < partes.length; i++) {
    indice += partes[i].length + 1;
  }
  editor.focus();
  editor.setSelectionRange(indice, indice);
  const antes = editor.scrollTop;
  editor.scrollTop = antes;
}

async function cargarEjemplos() {
  try {
    const datos = await (await fetch('/api/ejemplos')).json();
    const selector = $('ejemplo');
    selector.innerHTML = '<option value="">Cargar…</option>';
    (datos.ejemplos || []).forEach((e) => {
      const op = document.createElement('option');
      op.value = e.id;
      op.textContent = `${e.id} — ${e.titulo}`;
      selector.appendChild(op);
    });
  } catch (e) {
    console.error('No se pudieron cargar los ejemplos', e);
  }
}

async function cargarEjemplo(id) {
  if (!id) return;
  try {
    const datos = await (await fetch(`/api/ejemplo?id=${encodeURIComponent(id)}`)).json();
    if (typeof datos.codigo === 'string') {
      editor.value = datos.codigo;
      actualizarLineas();
      limpiarResultado();
    }
  } catch (e) {
    console.error('No se pudo cargar el ejemplo', e);
  }
}

async function cargarPlantillas() {
  try {
    const datos = await (await fetch('/api/plantillas')).json();
    const paleta = $('paleta');
    paleta.innerHTML = '';
    (datos.categorias || []).forEach((cat) => {
      const titulo = document.createElement('div');
      titulo.className = 'categoria';
      titulo.textContent = cat.titulo;
      paleta.appendChild(titulo);
      (cat.bloques || []).forEach((bloque) => {
        const boton = document.createElement('button');
        boton.type = 'button';
        boton.className = 'bloque';
        boton.dataset.texto = `${bloque.spec} ${bloque.sintaxis} ${bloque.descripcion}`.toLowerCase();
        const codigo = document.createElement('code');
        codigo.textContent = bloque.sintaxis;
        const nota = document.createElement('small');
        nota.textContent = bloque.descripcion;
        boton.append(codigo, nota);
        boton.addEventListener('click', () => insertar(bloque.plantilla));
        paleta.appendChild(boton);
      });
    });
  } catch (e) {
    console.error('No se pudieron cargar las plantillas', e);
  }
}

function limpiarResultado() {
  estado.textContent = 'Sin analizar';
  estado.className = 'estado';
  resumen.innerHTML = '';
  soluciones.innerHTML = '';
  explicacion.textContent = '';
  errores.innerHTML = '';
}

function mostrarErrores(lista) {
  errores.innerHTML = '';
  (lista || []).forEach((e) => {
    const boton = document.createElement('button');
    boton.type = 'button';
    boton.className = 'error-item';
    const titulo = document.createElement('strong');
    titulo.textContent = `Línea ${e.linea == null ? '?' : e.linea}${e.id != null ? ` · pista ${e.id}` : ''}: ${e.mensaje}`;
    const sugerencia = document.createElement('span');
    sugerencia.textContent = e.sugerencia || '';
    boton.append(titulo, sugerencia);
    boton.addEventListener('click', () => irALinea(e.linea));
    errores.appendChild(boton);
  });
}

function tablaSolucion(sol) {
  const tabla = document.createElement('table');
  tabla.className = 'tabla';
  const attrs = sol.atributos || {};
  Object.keys(attrs).forEach((clave) => {
    const fila = document.createElement('tr');
    const th = document.createElement('th');
    th.textContent = clave;
    const td = document.createElement('td');
    td.textContent = attrs[clave];
    fila.append(th, td);
    tabla.appendChild(fila);
  });
  return tabla;
}

function mostrarInforme(info) {
  estado.textContent = info.estado;
  estado.className = `estado ${info.estado}`;
  resumen.innerHTML = '';

  const anadir = (texto, clase) => {
    const p = document.createElement('div');
    if (clase) p.className = clase;
    p.textContent = texto;
    resumen.appendChild(p);
  };

  if (info.aviso) anadir(info.aviso, 'aviso');
  if (info.numero_soluciones != null) anadir(`Soluciones: ${info.numero_soluciones}`);
  if (info.unica != null) anadir(`Única: ${info.unica ? 'sí' : 'no'}`);
  if (info.irreductible != null) anadir(`Pistas irredundantes: ${info.irreductible ? 'sí' : 'no'}`);
  if (info.pistas_sobrantes && info.pistas_sobrantes.length) {
    anadir(`Pistas sobrantes: ${info.pistas_sobrantes.join(', ')}`);
  }
  if (info.minimalidad_fuerte != null) {
    anadir(`Minimalidad fuerte: ${info.minimalidad_fuerte}`);
  }

  soluciones.innerHTML = '';
  (info.soluciones || []).slice(0, 25).forEach((sol, i) => {
    const caja = document.createElement('div');
    caja.className = 'solucion';
    const titulo = document.createElement('h3');
    titulo.textContent = `Solución ${i + 1}`;
    caja.appendChild(titulo);
    (sol || []).forEach((entidad) => {
      const nombre = document.createElement('div');
      nombre.textContent = entidad.entidad;
      nombre.style.fontWeight = '600';
      caja.appendChild(nombre);
      caja.appendChild(tablaSolucion(entidad));
    });
    soluciones.appendChild(caja);
  });
}

async function analizar() {
  estado.textContent = 'Analizando…';
  estado.className = 'estado';
  const cuerpo = {
    codigo: editor.value,
    limite: Number($('limite').value) || 100,
    tiempo: Number($('tiempo').value) || 5,
    minimalidad: $('minimalidad').checked
  };
  try {
    const datos = await (await fetch('/api/analizar', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(cuerpo)
    })).json();
    mostrarErrores(datos.errores);
    if ( datos.ok ) mostrarInforme(datos.informe);
    else limpiarResultadoConErrores();
  } catch (e) {
    mostrarErrores([{linea: 0, id: null,
      mensaje: 'No se pudo conectar con el servidor.',
      sugerencia: 'Comprueba que el servidor esté en ejecución.'}]);
  }
}

function limpiarResultadoConErrores() {
  estado.textContent = 'Errores';
  estado.className = 'estado error';
  resumen.innerHTML = '';
  soluciones.innerHTML = '';
}

async function explicar() {
  explicacion.textContent = 'Generando explicación…';
  try {
    const datos = await (await fetch('/api/explicacion', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({codigo: editor.value})
    })).json();
    if (datos.ok) {
      explicacion.textContent = datos.texto || 'Sin explicación disponible.';
    } else {
      explicacion.textContent = (datos.errores || []).map((e) => e.mensaje).join('\n');
      mostrarErrores(datos.errores);
    }
  } catch (e) {
    explicacion.textContent = 'No se pudo conectar con el servidor.';
  }
}

function guardar() {
  localStorage.setItem('acertijoActual', editor.value);
  estado.textContent = 'Guardado localmente';
}

function descargar() {
  const blob = new Blob([editor.value], {type: 'text/plain;charset=utf-8'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'acertijo.pl';
  a.click();
  URL.revokeObjectURL(url);
}

function extraerLista(re) {
  const m = editor.value.match(re);
  return m ? m[1].split(',').map((s) => s.trim().replace(/^['"]|['"]$/g, '')).filter(Boolean) : [];
}

function actualizarAsistente() {
  const entidades = extraerLista(/entidades\s*\(\s*\[([^\]]*)\]/);
  const valores = extraerLista(/atributo\s*\(\s*tipo\s*,\s*\[([^\]]*)\]/);
  const rellenar = (sel, opciones) => {
    sel.innerHTML = '';
    opciones.forEach((op) => {
      const n = document.createElement('option');
      n.value = op;
      n.textContent = op;
      sel.appendChild(n);
    });
  };
  rellenar($('asistente-entidad'), entidades.length ? entidades : ['a']);
  rellenar($('asistente-hablante'), entidades.concat(['ninguno']).length ? entidades.concat(['ninguno']) : ['a']);
  const formulas = ['es(E, V)', 'no(es(E, V))', 'es(E, caballero)', 'es(E, truhan)',
                    'igual_tipo(E, E2)', 'distinto_tipo(E, E2)'];
  rellenar($('asistente-formula'), formulas);
}

function insertarPista() {
  const entidad = $('asistente-entidad').value || 'a';
  const hablante = $('asistente-hablante').value || entidad;
  const entidades = extraerLista(/entidades\s*\(\s*\[([^\]]*)\]/);
  const otra = entidades.find((e) => e !== entidad) || entidad;
  const valores = extraerLista(/atributo\s*\(\s*tipo\s*,\s*\[([^\]]*)\]/);
  const valor = valores[0] || 'caballero';
  const plantilla = $('asistente-formula').value || 'es(E, V)';
  const formula = plantilla
    .replace(/E2/g, otra)
    .replace(/E/g, entidad)
    .replace(/V/g, valor);
  const ids = Array.from(editor.value.matchAll(/pista\s*\(\s*(\d+)/g)).map((m) => Number(m[1]));
  const id = ids.length ? Math.max(...ids) + 1 : 1;
  insertar(`pista(${id}, ${hablante}, ${formula}).\n`);
}

$('ejemplo').addEventListener('change', (e) => cargarEjemplo(e.target.value));
$('editor').addEventListener('input', () => { actualizarLineas(); actualizarAsistente(); });
$('editor').addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    e.preventDefault();
    insertar('  ');
  }
});
$('btn-analizar').addEventListener('click', analizar);
$('btn-explicar').addEventListener('click', explicar);
$('btn-guardar').addEventListener('click', guardar);
$('btn-descargar').addEventListener('click', descargar);
$('btn-insertar-pista').addEventListener('click', insertarPista);
$('buscar-bloque').addEventListener('input', (e) => {
  const filtro = e.target.value.toLowerCase();
  document.querySelectorAll('.bloque').forEach((b) => {
    b.style.display = (b.dataset.texto || '').includes(filtro) ? '' : 'none';
  });
});

actualizarLineas();
actualizarAsistente();
cargarEjemplos();
cargarPlantillas();
const guardado = localStorage.getItem('acertijoActual');
if (guardado) editor.value = guardado;
else cargarEjemplo('isla_1');
