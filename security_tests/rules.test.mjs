import {readFile} from 'node:fs/promises';
import {before, after, beforeEach, test} from 'node:test';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, collection, setDoc, getDoc, getDocs, updateDoc, deleteDoc, serverTimestamp, Timestamp} from 'firebase/firestore';
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-historial-medico',
    firestore:{host:'127.0.0.1',port:8080,rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8')}});
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const db = uid => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const path = 'pacientes/A/registros/registro1';
const data = () => ({titulo:'Control ficticio',fecha:Timestamp.fromDate(new Date('2025-01-10T00:00:00Z')),
  categoria:'Consulta',descripcion:'Descripción ficticia.',autorUid:'A',origen:'paciente',creadoEn:serverTimestamp()});
async function seed() { await assertSucceeds(setDoc(doc(db('A'),path),data())); }
test('Propietario puede crear, leer y listar sus registros',async()=>{
  await seed();
  await assertSucceeds(getDoc(doc(db('A'),path)));
  await assertSucceeds(getDocs(collection(db('A'),'pacientes/A/registros')));
});
test('Otra cuenta no puede leer, listar ni crear registros ajenos',async()=>{
  await seed();
  await assertFails(getDoc(doc(db('B'),path)));
  await assertFails(getDocs(collection(db('B'),'pacientes/A/registros')));
  await assertFails(setDoc(doc(db('B'),'pacientes/A/registros/otro'),data()));
});
test('Sin sesión no puede leer ni escribir',async()=>{
  await seed();
  await assertFails(getDoc(doc(db(null),path)));
  await assertFails(setDoc(doc(db(null),'pacientes/A/registros/otro'),data()));
});
test('No puede falsificar autor o procedencia profesional',async()=>{
  await assertFails(setDoc(doc(db('A'),path),{...data(),autorUid:'B'}));
  await assertFails(setDoc(doc(db('A'),path),{...data(),origen:'profesional'}));
});
test('Rechaza campos extra, categorías desconocidas y texto fuera de límites',async()=>{
  for(const patch of [{rol:'medico'},{categoria:'Inventada'},{titulo:'A'},{descripcion:'x'.repeat(4001)}]) {
    await assertFails(setDoc(doc(db('A'),path),{...data(),...patch}));
  }
});
test('Rechaza fecha futura y fecha de creación falsificada',async()=>{
  await assertFails(setDoc(doc(db('A'),path),{...data(),fecha:Timestamp.fromDate(new Date('2999-01-01'))}));
  await assertFails(setDoc(doc(db('A'),path),{...data(),creadoEn:Timestamp.fromDate(new Date('2020-01-01'))}));
});
test('Ni el propietario puede modificar ni eliminar un registro',async()=>{
  await seed();
  await assertFails(updateDoc(doc(db('A'),path),{titulo:'Reescrito'}));
  await assertFails(deleteDoc(doc(db('A'),path)));
});
test('El perfil conserva sus permisos anteriores',async()=>{
  const profile={nombre:'Alex',fechaNacimiento:'2000-01-01',alergias:'',antecedentes:'',actualizadoEn:serverTimestamp()};
  await assertSucceeds(setDoc(doc(db('A'),'pacientes/A'),profile));
  await assertSucceeds(getDoc(doc(db('A'),'pacientes/A')));
  await assertFails(getDoc(doc(db('B'),'pacientes/A')));
});
