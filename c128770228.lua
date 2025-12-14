--카드명 : 스파클 아르카디아 ○○ (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,Synchro.NonTunerEx(Card.IsSetCard,0x760),1,99)

	--① 싱크로 소환 성공시 '스파클 아르카디아 베이스' 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)

	--② 필드에서 효과 발동시 그 카드 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
s.listed_series={0x760}
s.listed_names={128770222} -- 스파클 아르카디아 베이스 카드코드

--① 조건 : 싱크로 소환 성공시
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
--① 대상 : 덱에서 '스파클 아르카디아 베이스' 세트할 수 있는지
function s.setfilter(c)
	return c:IsCode(128770222) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
	end
end

--② 조건 : 필드의 몬스터 OR 앞면의 마/함 효과가 발동했을 때
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return (rc:IsOnField() and (rc:IsType(TYPE_MONSTER) or (rc:IsType(TYPE_SPELL+TYPE_TRAP) and rc:IsFaceup())))
end
--② 대상 : 그 카드 파괴
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return rc:IsDestructable() end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
end
--② 처리 : 파괴
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsDestructable() then
		Duel.Destroy(rc,REASON_EFFECT)
	end
end
