--어보미네이션 유닛 콜 (지속 함정)
local s,id=GetID()
function s.initial_effect(c)
	--①: 발동 처리 (프리체인)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--②: 기계족 몬스터를 튜너로 취급
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.tunertg)
	e1:SetValue(TYPE_MONSTER+TYPE_TUNER+TYPE_EFFECT)
	c:RegisterEffect(e1)

	--③: 어보미네이션 특수소환 시 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

-- 기계족 몬스터를 튜너로 취급
function s.tunertg(e,c)
	return c:IsRace(RACE_MACHINE)
end

-- 어보미네이션 특수 소환 체크
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsControler(tp) and c:IsSetCard(0xc42) end,1,nil)
end

-- 파괴 대상 선택 (싱크로 몬스터 여부 확인)
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=1
	if Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_SYNCHRO) then
		ct=2
	end
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

-- 파괴 실행
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
