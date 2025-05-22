--어보미네이션 서지 배리어
local s,id=GetID()
function s.initial_effect(c)
	--① 카드 발동 (프리체인)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--①: 어보미넌스 싱크로 소환시 체인 봉쇄
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,1)
	e1:SetCondition(s.chainlimit_con)
	e1:SetValue(s.chainlimit_val)
	c:RegisterEffect(e1)

	--②: 어보미네이션 몬스터 특수 소환 시 파괴 (1턴 1회)
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

----------------------------
-- ① 어보미넌스 싱크로 체인 봉쇄
----------------------------
function s.chainlimit_con(e)
	local tp=e:GetHandlerPlayer()
	local ph=Duel.GetCurrentPhase()
	return Duel.GetCurrentChain()==0 and ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end
function s.chainlimit_val(e,re,tp)
	local rc=re:GetHandler()
	return rc:IsType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) and Duel.GetFlagEffect(tp,id)==1
end

----------------------------
-- ② 어보미네이션 특수 소환 시 파괴
----------------------------
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsControler(tp) and c:IsSetCard(0xc42) end,1,nil)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=1
	if Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0xc42) end,tp,LOCATION_MZONE,0,1,nil) then
		ct=2
	end
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
