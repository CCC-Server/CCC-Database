--올마이티 셀레스티얼 타이탄-원더 크로스 이터니티
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --싱크로 소환 절차
    Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(s.matfilter),1,1,Synchro.NonTunerEx(s.matfilter),2,99)
    --싱크로 소환으로만 소환 가능
	local e0=Effect.CreateEffect(c)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SINGLE_RANGE)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.synlimit)
	c:RegisterEffect(e0)
    --Count the number of non-Tuner materials
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_MATERIAL_CHECK)
	e1:SetValue(s.valcheck)
	c:RegisterEffect(e1)
    --atk/def
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)
    --① 효과: 효과 파괴 내성 + 대상 지정 불가
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e4:SetValue(1)
    c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e5:SetValue(1)
    c:RegisterEffect(e5)
    --② 효과: 상대 필드에 몬스터가 공격 표시로 소환될 때마다 발동
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,0))
    e6:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_SUMMON_SUCCESS)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.atkcon)
    e6:SetTarget(s.atktg)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)
	-- material count 라벨 연결
    e6:SetLabelObject(e1)
    local e7=e6:Clone()
    e7:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e7)
	e7:SetLabelObject(e1)
end

s.listed_series={0xc02}
s.synchro_tuner_required=1
s.synchro_nt_required=2

function s.matfilter(c,val,scard,sumtype,tp)
	return c:IsRace(RACE_FAIRY,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA,0,nil)*300
end
function s.atkfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_FAIRY)
end

--싱크로 소환 시 사용된 모든 싱크로 몬스터 수 저장 (튜너 + 비튜너 포함)
function s.mfilter(c)
	return c:IsType(TYPE_SYNCHRO)
end
function s.valcheck(e,c)
    local ct=c:GetMaterial():FilterCount(Card.IsType,nil,TYPE_SYNCHRO)
    local objs=e:GetLabelObject()
    if type(objs)=="table" then
        for _,eff in ipairs(objs) do
            eff:SetLabel(ct)
        end
    end
end

function s.posfilter(c,tp)
	return c:IsControler(1-tp) and c:IsPosition(POS_FACEUP_ATTACK)
end
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return not eg:IsContains(e:GetHandler()) and eg:IsExists(s.posfilter,1,nil,tp)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsRelateToEffect(e) end
	Duel.SetTargetCard(eg:Filter(s.posfilter,nil,tp))
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local ct=e:GetLabel()
    if ct==nil or ct==0 then return end
	local g=Duel.GetTargetCards(e):Match(Card.IsFaceup,nil)
	if #g==0 then return end
	local dg=Group.CreateGroup()
	local c=e:GetHandler()
	for tc in g:Iter() do
		local preatk=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*(-700))
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
		if preatk~=0 and tc:GetAttack()==0 then dg:AddCard(tc) end
	end
	if #dg==0 then return end
	Duel.BreakEffect()
	Duel.Destroy(dg,REASON_EFFECT)
end