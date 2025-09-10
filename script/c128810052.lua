--올마이티 셀레스티얼 타이탄-이터니티 미라클
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,3,3,Synchro.NonTunerEx(s.matfilter),1,1)
	c:AddMustBeSynchroSummoned()
	Pendulum.AddProcedure(c,false)
	--Cannot be destroyed by effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--Change a monster effect activated by the opponent
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return rp==1-tp and re:IsMonsterEffect() end)
	e3:SetCost(s.cost)
	e3:SetCondition(s.chcon)
	e3:SetTarget(s.chngtg)
	e3:SetOperation(s.chngop)
	c:RegisterEffect(e3)
end
s.listed_series={0xc02}
s.synchro_nt_required=1
function s.matfilter(c,val,scard,sumtype,tp)
	return c:IsRace(RACE_FAIRY,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

function s.costfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.costfilter,tp,LOCATION_EXTRA,0,nil)
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 and #g>0 and c:IsAbleToRemoveAsCost() end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_REMOVE)
	Duel.Remove(sg,POS_FACEUP,REASON_COST)
end
function s.fairyfilter(c)
	return c:IsRace(RACE_FAIRY) and c:IsMonster() and (c:IsFaceup() or not c:IsOnField())
end
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and (re:IsMonsterEffect() or ((rc:IsSpell() or rc:IsTrap()) and re:IsHasType(EFFECT_TYPE_ACTIVATE)))
end
function s.chngtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fairyfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
end
function s.chngop(e,tp,eg,ep,ev,re,r,rp)
	local g=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,g)
	Duel.ChangeChainOperation(ev,s.repop)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(1-tp,aux.NecroValleyFilter(s.fairyfilter),tp,0,LOCATION_GRAVE,1,1,nil,e,1-tp)
		local tc=sg:GetFirst() 
		if tc then
			Duel.SpecialSummon(tc,0,1-tp,1-tp,false,false,POS_FACEUP)
		end
end
